# Translation.psm1



$global:languagesCsv = ConvertFrom-Csv -InputObject ( Get-Content "$PSScriptRoot/Languages.csv" -Raw )

$languageToCode = @{}
$codeToLanguage = @{}
foreach($row in $global:languagesCsv)
{
    $languageToCode[$row.Language] = $row.Code
    $codeToLanguage[$row.Code] = $row.Language
}

class Language : System.Management.Automation.IValidateSetValuesGenerator
{
    [String[]] GetValidValues()
    {
        $languages = $global:languagesCsv | ForEach-Object { $_.Language }
        $codes     = $global:languagesCsv | ForEach-Object { $_.Code }

        return $languages + $codes
    }
}



<#
    .DESCRIPTION
    A function that uses the free Google Translate API to retrieve information.

    .PARAMETER InputObject
    Text to translate or get some type of information depending on the ReturnType parameter.

    .PARAMETER SourceLanguage
    Source language as code or English.

    .PARAMETER TargetLanguage
    Target language as code or English.

    .PARAMETER ReturnType
    The type of inforation to return, it can be any of these:

    [Translation, Alternative, LanguageDetection, LanguageDetectionAsEnglishWord, Dictionary, Definition, Synonym, Example]

    .NOTES
    This function uses the free google translate api, if you try to do so many calls it will block (you will probably only find issues when doing parallelism).
#>
function Invoke-GoogleTranslate(
    [Parameter(Mandatory=$true)]
    [string] $InputObject,
    [ValidateSet([Language])]
    [Alias('From')]
    [string] $SourceLanguage = 'auto',
    [ValidateSet([Language])]
    [Alias('To')]
    [string] $TargetLanguage,
    [ValidateSet('Translation', 'Alternative', 'LanguageDetection', 'LanguageDetectionAsEnglishWord', 'Dictionary', 'Definition', 'Synonym', 'Example')]
    [string] $ReturnType = 'Translation'
) {
    if ($ListOfOneWordReturnType.Contains($ReturnType) -and ($InputObject.Trim().Contains(' ') -or $InputObject.Trim().Contains("`n")))
    {
        Write-Error "The return type '$ReturnType' only works for single words, your input is '$InputObject'."
    }
    if ($ListReturnTypeThatTheTargetLanguageIsRequired.Contains($ReturnType) -and -not $TargetLanguage)
    {
        Write-Error "You must specify a the TargetLanguage if the ReturnType is '$ReturnType'."
    }

    $sourceLanguageCode, $targetLanguageCode = TryConvertLanguageToCode $SourceLanguage $TargetLanguage

    $query = [uri]::EscapeDataString($InputObject)
    
    $returnTypeAsQueryParameter = GetReturnTypeAsQueryParameter -ReturnType $ReturnType

    $uri = "https://translate.googleapis.com/translate_a/single?client=gtx&dj=1&sl=$sourceLanguageCode&tl=$targetLanguageCode&dt=t&q=$query&dt=$returnTypeAsQueryParameter"

    $response = (Invoke-WebRequest -Uri $uri -Method Get).Content | ConvertFrom-Json

    $result = switch ($ReturnType)
    {
        LanguageDetection { $response.src }
        LanguageDetectionAsEnglishWord { $codeToLanguage[$response.src] }
        Translation { $response.sentences | Select-Object -ExpandProperty trans | Join-String }
        Alternative
        {
            [PSCustomObject]@{
                SourceLanguage = $response.src
                AlternativesPerLine = $response.alternative_translations
                    | Where-Object { $null -ne $_.alternative }
                    | Group-Object { $_.src_phrase }
                    | ForEach-Object { 
                        [PSCustomObject]@{
                            SourceLine = $_.Name
                            TranslationAlternatives = ($_.Group[0].alternative | ForEach-Object { $_.word_postproc })
                        }
                    }
            }
        }
        Dictionary
        {
            [PSCustomObject]@{
                SourceLanguage = $response.src
                Dictionary = $response.dict | ForEach-Object { 
                    [PSCustomObject]@{
                        WordType = $_.pos
                        Terms = $_.terms
                        Entries = foreach ($wordInfo in $_.entry)
                        {
                            [PSCustomObject]@{
                                Word = $wordInfo.word
                                ReverseTranslations = $wordInfo.reverse_translation
                                Score = $wordInfo.score
                            }
                        }
                    }
                }
            }
        }
        Definition 
        { 
            [PSCustomObject]@{
                SourceLanguage = $response.src
                Definitions = $response.definitions
            }
        }
        Synonym
        { 
            [PSCustomObject]@{
                SourceLanguage = $response.src
                Translation = $response.sentences.trans
                SynonymSets = foreach ($set in $response.synsets)
                {
                    [PSCustomObject]@{
                        WordType = $set.pos
                        SynonymGroups = $set.entry | ForEach-Object { ,@(,$_.synonym) }
                    }
                }
            }
        }
        Example
        { 
            [PSCustomObject]@{
                SourceLanguage = $response.src
                Translation = $response.sentences.trans
                Examples = $response.examples[0] | Select-Object -ExpandProperty example | Select-Object -ExpandProperty text
            }
        }
    }

    return $result
}

function TryConvertLanguageToCode([string] $SourceLanguage, [string] $TargetLanguage)
{
    $languageCodes = @($SourceLanguage, $TargetLanguage)

    if ($languageToCode.ContainsKey($SourceLanguage))
    {
        $languageCodes[0] = $languageToCode[$SourceLanguage]
    }
    if ($languageToCode.ContainsKey($TargetLanguage))
    {
        $languageCodes[1] = $languageToCode[$TargetLanguage]
    }

    return $languageCodes
}

# https://wiki.freepascal.org/Using_Google_Translate
function GetReturnTypeAsQueryParameter($ReturnType)
{
    $result = switch ($ReturnType)
    {
        Translation { 't' }
        Alternative { 'at' }
        Dictionary { 'bd' }
        Definition { 'md' }
        Synonym { 'ss' }
        Example { 'ex' }

        default { Write-Warning "Unexpected ReturnType value '$ReturnType'" }
    }

    return $result
}

$ListOfOneWordReturnType = @('Definition', 'Synonym', 'Example')
$ListReturnTypeThatTheTargetLanguageIsRequired = @('Translation', 'Alternative', 'Dictionary', 'Example')



Export-ModuleMember -Function *-*