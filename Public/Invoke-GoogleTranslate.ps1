# https://wiki.freepascal.org/Using_Google_Translate
$ReturnTypeToQueryParameter = @{
    Translation   = 't'
    Alternative   = 'at'
    Transcription = 'rm'
    Dictionary    = 'bd'
    Definition    = 'md'
    Synonym       = 'ss'
    Example       = 'ex'
    #SeeAlso    = 'rw' # it seems to be the same as Translation
}

$ListOfSingleWordReturnType = @('Definition', 'Synonym', 'Example')
$ListOfReturnTypeThatTheTargetLanguageIsRequired = @('Translation', 'Alternative', 'Dictionary', 'Example')


function Invoke-GoogleTranslate {

    [OutputType([PSCustomObject], [PSCustomObject[]])]
    param (
        [Alias('Query')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $InputObject,

        [ValidateSet('Translation', 'Alternative', 'Transcription', 'DetectedLanguage', 'Dictionary', 'Definition', 'Synonym', 'Example')]
        [string] $ReturnType = 'Translation'
    )

    dynamicparam {
        $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $sourceAttributes = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $sourceAttributes.Add((New-Object System.Management.Automation.ParameterAttribute))
        $runtimeParameterDictionary.Add('SourceLanguageCode', (New-Object System.Management.Automation.RuntimeDefinedParameter('SourceLanguageCode', [string], $sourceAttributes)))

        $targetAttributes = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $targetParamAttribute = New-Object System.Management.Automation.ParameterAttribute
        $targetParamAttribute.Mandatory = $ReturnType -in $ReturnTypeThatTheTargetLanguageIsRequired
        $targetAttributes.Add($targetParamAttribute)
        
        $targetParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TargetLanguageCode', [string], $targetAttributes)
        $runtimeParameterDictionary.Add('TargetLanguageCode', $targetParam)

        return $runtimeParameterDictionary
    }

    begin {
        $SourceLanguageCode = if ($PsBoundParameters.ContainsKey('SourceLanguageCode')) { $PsBoundParameters['SourceLanguageCode'] } else { 'auto' }
        $TargetLanguageCode = $PsBoundParameters['TargetLanguageCode']
    }

    process {
        if ($ReturnType -in $ListOfSingleWordReturnType -and ($InputObject.Trim().Contains(' ') -or $InputObject.Trim().Contains("`n"))) {
            Write-Error "The return type '$ReturnType' only works for single words, your input is '$InputObject'."
        }
        if ($ReturnType -in $ListOfReturnTypeThatTheTargetLanguageIsRequired -and -not $TargetLanguageCode) {
            Write-Error "You must specify a the TargetLanguageCode if the ReturnType is '$ReturnType'."
        }

        $returnTypeAsQueryParameter = $ReturnTypeToQueryParameter[$ReturnType]

        $query = if ($ReturnType -eq 'Example') {
            # 'Example' does not work if there are capital letters
            [uri]::EscapeDataString($InputObject.ToLowerInvariant())
        }
        else { [uri]::EscapeDataString($InputObject) }

        $uri = "https://translate.googleapis.com/translate_a/single?client=gtx&dj=1&q=$query&sl=$SourceLanguageCode&tl=$TargetLanguageCode&dt=t&dt=$returnTypeAsQueryParameter"

        Write-Verbose -Message "Requesting: $uri"

        try {
            $data = Invoke-RestMethod -Uri $uri -Method Get

            if ($VerbosePreference) {
                Write-Verbose -Message ($data | ConvertTo-Json -Depth 10)
            }

            $result = switch ($ReturnType) {
                DetectedLanguage {
                    [PSCustomObject]@{
                        SourceLanguageCode = $data.src
                    }
                }
                Translation {
                    [PSCustomObject]@{
                        SourceLanguageCode = $data.src
                        TargetLanguageCode = $TargetLanguageCode
                        Translation        = $data.sentences | Select-Object -ExpandProperty trans | Join-String
                    }
                }
                Alternative {
                    [PSCustomObject]@{
                        SourceLanguageCode  = $data.src
                        TargetLanguageCode  = $TargetLanguageCode
                        AlternativesPerLine = $data.alternative_translations
                        | Where-Object { $null -ne $_.alternative }
                        | Group-Object { $_.src_phrase }
                        | ForEach-Object { 
                            [PSCustomObject]@{
                                SourceLine              = $_.Name
                                TranslationAlternatives = @($_.Group[0].alternative | ForEach-Object { $_.word_postproc })
                            }
                        }
                    }
                }
                Transcription {
                    [PSCustomObject]@{
                        SourceLanguageCode  = $data.src
                        TargetLanguageCode  = $TargetLanguageCode
                        Translation         = $data.sentences[0].trans
                        Original            = $data.sentences[0].orig
                        Transliteration     = $data.sentences[1].src_translit
                        Confidence          = $data.confidence
                    }
                }
                Dictionary {
                    [PSCustomObject]@{
                        SourceLanguageCode = $data.src
                        Dictionary         = $data.dict | ForEach-Object { 
                            [PSCustomObject]@{
                                WordClass = $_.pos
                                Terms     = $_.terms
                                Entries   = foreach ($wordData in $_.entry) {
                                    [PSCustomObject]@{
                                        Word                = $wordData.word
                                        ReverseTranslations = $wordData.reverse_translation
                                        Score               = $wordData.score
                                    }
                                }
                            }
                        }
                    }
                }
                Definition { 
                    [PSCustomObject]@{
                        SourceLanguageCode = $data.src
                        Definitions        = foreach ($definitionData in $data.definitions) {
                            [PSCustomObject]@{
                                WordClass = $definitionData.pos
                                Glossary  = @($definitionData.entry | Select-Object -ExpandProperty gloss)
                            }
                        }
                    }
                }
                Synonym { 
                    [PSCustomObject]@{
                        SourceLanguageCode        = $data.src
                        TargetLanguageCode        = $TargetLanguageCode
                        Translation               = $data.sentences.trans
                        SynonymGroupsPerWordClass = foreach ($set in $data.synsets) {
                            [PSCustomObject]@{
                                WordClass = $set.pos
                                Groups    = foreach ($synonymData in $set.entry) {
                                    [PSCustomObject]@{
                                        DefinitionId = $synonymData.definition_id
                                        Synonyms     = @($synonymData.synonym)
                                    }
                                }
                            }
                        }
                    }
                }
                Example {
                    [PSCustomObject]@{
                        SourceLanguageCode = $data.src
                        TargetLanguageCode = $TargetLanguageCode
                        Translation        = $data.sentences.trans
                        Examples           = @($data.examples[0] | Select-Object -ExpandProperty example | Select-Object -ExpandProperty text)
                    }
                }
            }

            return $result
        }
        catch [System.Net.WebException] {
            Write-Error "A network error occurred: $($_.Exception.Message)"
            return $null
        }
        catch [System.Net.Sockets.SocketException] {
            Write-Error "Host not found or no internet connection: $($_.Exception.Message)"
            return $null
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-Error "HTTP error occurred: $($_.Exception.Message)"
            return $null
        }
        catch {
            Write-Error "An unknown error occurred: $($_.Exception.Message)"
            return $null
        }
    }
}



Register-ArgumentCompleter -CommandName 'Invoke-GoogleTranslate' -ParameterName 'SourceLanguageCode' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $languages = Get-GoogleTranslateSupportedLanguage -TargetLanguageCode 'en'

    $languages | Where-Object { 
        ($_.Type -eq 'Source' -or $_.Type -eq 'Both') -and ($_.Code -like "$wordToComplete*" -or $_.Name -like "$wordToComplete*")
    } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Code, 
            "$($_.Code) ($($_.Name))", 
            'ParameterValue', 
            $_.Name
        )
    }
}

Register-ArgumentCompleter -CommandName 'Invoke-GoogleTranslate' -ParameterName 'TargetLanguageCode' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $languages = Get-GoogleTranslateSupportedLanguage -TargetLanguageCode 'en'

    $languages | Where-Object { 
        ($_.Type -eq 'Target' -or $_.Type -eq 'Both') -and ($_.Code -like "$wordToComplete*" -or $_.Name -like "$wordToComplete*")
    } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Code, 
            "$($_.Code) ($($_.Name))", 
            'ParameterValue', 
            $_.Name
        )
    }
}
