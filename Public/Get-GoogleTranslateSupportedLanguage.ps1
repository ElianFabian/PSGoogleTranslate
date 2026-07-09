<#
.SYNOPSIS
    Retrieves the list of languages supported by the Google Translate API.

.DESCRIPTION
    This function queries the Google Translate API (or uses a fallback cache) to get 
    the list of language codes. It utilizes Dynamic Parameters to provide 
    'TargetLanguageCode' as a required argument for specific operations.

.PARAMETER Refresh
    Forces a cache refresh by querying the Google Translate API again, ignoring 
    the existing local cache.

.PARAMETER TargetLanguageCode
    (Dynamic) The ISO language code (e.g., 'en', 'es') for the target language.
    This parameter is mandatory and supports tab-completion.

.EXAMPLE
    Get-GoogleTranslateSupportedLanguage -TargetLanguageCode en
    Returns the language configuration for 'en' and initializes the cache.

.EXAMPLE
    Get-GoogleTranslateSupportedLanguage -Refresh -TargetLanguageCode es
    Forces a fresh API query and sets the target language to Spanish.
#>
function Get-GoogleTranslateSupportedLanguage {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [switch] $Refresh
    )

    dynamicparam {
        if ($null -eq $script:GoogleLanguagesCache -or $Refresh) {
            $script:GoogleLanguagesCache = $script:FallbackLanguages 
        }

        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        $ParamAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttribute.Mandatory = $true
        $AttributeCollection.Add($ParamAttribute)

        $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TargetLanguageCode', [string], $AttributeCollection)
        $DynParamDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $DynParamDictionary.Add('TargetLanguageCode', $RuntimeParam)

        return $DynParamDictionary
    }

    begin {
        $TargetLanguageCode = $PsBoundParameters['TargetLanguageCode']
    }

    process {
        if ($null -eq $script:GoogleLanguagesCache -or $Refresh) {
            Write-Verbose "Cache miss or refresh requested. Querying Google Translate API..."

            $RequestParams = @{
                Method     = 'GET'
                Uri        = "https://translate.googleapis.com/translate_a/l?client=gtx&hl=$TargetLanguageCode"
                TimeoutSec = 5
            }

            try {
                Write-Verbose "Sending request to URI: $($RequestParams.Uri)"
                $RawData = Invoke-RestMethod @RequestParams
            
                $LanguageList = @()

                if ($null -ne $RawData.sl) {
                    foreach ($Property in $RawData.sl.psobject.Properties) {
                        $LanguageList += [PSCustomObject]@{
                            Code = $Property.Name
                            Name = $Property.Value
                            Type = 'Source'
                        }
                    }
                }

                if ($null -ne $RawData.tl) {
                    foreach ($Property in $RawData.tl.psobject.Properties) {
                        $ExistingMatch = $LanguageList | Where-Object { $_.Code -eq $Property.Name }
                        if ($ExistingMatch) {
                            $ExistingMatch.Type = 'Both'
                        }
                        else {
                            $LanguageList += [PSCustomObject]@{
                                Code = $Property.Name
                                Name = $Property.Value
                                Type = 'Target'
                            }
                        }
                    }
                }

                $script:GoogleLanguagesCache = $LanguageList
                Write-Verbose "Successfully updated cache with $($script:GoogleLanguagesCache.Count) languages."
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                $StatusCode = $_.Exception.Response.StatusCode
                Write-Error "API request failed with HTTP Status Code: $StatusCode. Defaulting to local fallback data."
                $script:GoogleLanguagesCache = $script:FallbackLanguages
            }
            catch {
                Write-Verbose "An unexpected network or contract parsing error occurred: $_"
                Write-Warning "Could not connect to the language service. Reverting to built-in fallback dataset."
                $script:GoogleLanguagesCache = $script:FallbackLanguages
            }
        }
        else {
            Write-Verbose "Cache hit. Returning cached data."
        }

        return $script:GoogleLanguagesCache
    }
}

$script:GoogleLanguagesCache = $null

# Last fetched: 09-07-2026
$script:FallbackLanguages = @(
    [PSCustomObject]@{ Code = 'aa'; Name = 'Afar'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ab'; Name = 'Abkhaz'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ace'; Name = 'Acehnese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ach'; Name = 'Acholi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'af'; Name = 'Afrikaans'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ak'; Name = 'Twi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'alz'; Name = 'Alur'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'am'; Name = 'Amharic'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ar'; Name = 'Arabic'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'as'; Name = 'Assamese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'auto'; Name = 'Detect language'; Type = 'Source' }
    [PSCustomObject]@{ Code = 'av'; Name = 'Avar'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'awa'; Name = 'Awadhi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ay'; Name = 'Aymara'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'az'; Name = 'Azerbaijani'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ba'; Name = 'Bashkir'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bal'; Name = 'Baluchi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ban'; Name = 'Balinese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bbc'; Name = 'Batak Toba'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bci'; Name = 'Baoulé'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'be'; Name = 'Belarusian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bem'; Name = 'Bemba'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ber'; Name = 'Tamazight (Tifinagh)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ber-Lat'; Name = 'Tamazight'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bew'; Name = 'Betawi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bg'; Name = 'Bulgarian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bho'; Name = 'Bhojpuri'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bik'; Name = 'Bikol'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bm'; Name = 'Bambara'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bm-Nkoo'; Name = 'NKo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bn'; Name = 'Bengali'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bo'; Name = 'Tibetan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'br'; Name = 'Breton'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bs'; Name = 'Bosnian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bts'; Name = 'Batak Simalungun'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'btx'; Name = 'Batak Karo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'bua'; Name = 'Buryat'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ca'; Name = 'Catalan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ce'; Name = 'Chechen'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ceb'; Name = 'Cebuano'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'cgg'; Name = 'Kiga'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ch'; Name = 'Chamorro'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'chk'; Name = 'Chuukese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'chm'; Name = 'Meadow Mari'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ckb'; Name = 'Kurdish (Sorani)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'cnh'; Name = 'Hakha Chin'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'co'; Name = 'Corsican'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'crh'; Name = 'Crimean Tatar (Cyrillic)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'crh-Lat'; Name = 'Crimean Tatar (Latin)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'crs'; Name = 'Seychellois Creole'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'cs'; Name = 'Czech'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'cv'; Name = 'Chuvash'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'cy'; Name = 'Welsh'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'da'; Name = 'Danish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'de'; Name = 'German'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'din'; Name = 'Dinka'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'doi'; Name = 'Dogri'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'dov'; Name = 'Dombe'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'dv'; Name = 'Dhivehi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'dyu'; Name = 'Dyula'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'dz'; Name = 'Dzongkha'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ee'; Name = 'Ewe'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'el'; Name = 'Greek'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'en'; Name = 'English'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'eo'; Name = 'Esperanto'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'es'; Name = 'Spanish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'et'; Name = 'Estonian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'eu'; Name = 'Basque'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fa'; Name = 'Persian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fa-AF'; Name = 'Dari'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ff'; Name = 'Fulani'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fi'; Name = 'Finnish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fj'; Name = 'Fijian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fo'; Name = 'Faroese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fon'; Name = 'Fon'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fr'; Name = 'French'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fr-CA'; Name = 'French (Canada)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fur'; Name = 'Friulian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'fy'; Name = 'Frisian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ga'; Name = 'Irish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gaa'; Name = 'Ga'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gd'; Name = 'Scots Gaelic'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gl'; Name = 'Galician'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gn'; Name = 'Guarani'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gom'; Name = 'Konkani'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gu'; Name = 'Gujarati'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'gv'; Name = 'Manx'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ha'; Name = 'Hausa'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'haw'; Name = 'Hawaiian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hi'; Name = 'Hindi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hil'; Name = 'Hiligaynon'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hmn'; Name = 'Hmong'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hr'; Name = 'Croatian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hrx'; Name = 'Hunsrik'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ht'; Name = 'Haitian Creole'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hu'; Name = 'Hungarian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'hy'; Name = 'Armenian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'iba'; Name = 'Iban'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'id'; Name = 'Indonesian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ig'; Name = 'Igbo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ilo'; Name = 'Ilocano'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'is'; Name = 'Icelandic'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'it'; Name = 'Italian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'iu'; Name = 'Inuktut (Syllabics)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'iu-Latn'; Name = 'Inuktut (Latin)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'iw'; Name = 'Hebrew'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ja'; Name = 'Japanese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'jam'; Name = 'Jamaican Patois'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'jw'; Name = 'Javanese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ka'; Name = 'Georgian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kac'; Name = 'Jingpo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kek'; Name = 'Qʼeqchiʼ'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kg'; Name = 'Kikongo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kha'; Name = 'Khasi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kk'; Name = 'Kazakh'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kl'; Name = 'Kalaallisut'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'km'; Name = 'Khmer'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kn'; Name = 'Kannada'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ko'; Name = 'Korean'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kr'; Name = 'Kanuri'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kri'; Name = 'Krio'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ktu'; Name = 'Kituba'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ku'; Name = 'Kurdish (Kurmanji)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'kv'; Name = 'Komi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ky'; Name = 'Kyrgyz'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'la'; Name = 'Latin'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lb'; Name = 'Luxembourgish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lg'; Name = 'Luganda'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'li'; Name = 'Limburgish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lij'; Name = 'Ligurian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lmo'; Name = 'Lombard'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ln'; Name = 'Lingala'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lo'; Name = 'Lao'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lt'; Name = 'Lithuanian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ltg'; Name = 'Latgalian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lua'; Name = 'Tshiluba'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'luo'; Name = 'Luo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lus'; Name = 'Mizo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'lv'; Name = 'Latvian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mad'; Name = 'Madurese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mai'; Name = 'Maithili'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mak'; Name = 'Makassar'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mam'; Name = 'Mam'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mfe'; Name = 'Mauritian Creole'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mg'; Name = 'Malagasy'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mh'; Name = 'Marshallese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mi'; Name = 'Maori'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'min'; Name = 'Minang'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mk'; Name = 'Macedonian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ml'; Name = 'Malayalam'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mn'; Name = 'Mongolian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mni-Mte'; Name = 'Meiteilon (Manipuri)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mr'; Name = 'Marathi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ms'; Name = 'Malay'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ms-Arab'; Name = 'Malay (Jawi)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mt'; Name = 'Maltese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'mwr'; Name = 'Marwadi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'my'; Name = 'Myanmar (Burmese)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ndc-ZW'; Name = 'Ndau'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ne'; Name = 'Nepali'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'new'; Name = 'Nepalbhasa (Newari)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'nhe'; Name = 'Nahuatl (Eastern Huasteca)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'nl'; Name = 'Dutch'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'no'; Name = 'Norwegian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'nr'; Name = 'Ndebele (South)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'nso'; Name = 'Sepedi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'nus'; Name = 'Nuer'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ny'; Name = 'Chichewa'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'oc'; Name = 'Occitan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'om'; Name = 'Oromo'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'or'; Name = 'Odia (Oriya)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'os'; Name = 'Ossetian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pa'; Name = 'Punjabi (Gurmukhi)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pa-Arab'; Name = 'Punjabi (Shahmukhi)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pag'; Name = 'Pangasinan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pam'; Name = 'Kapampangan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pap'; Name = 'Papiamento'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pl'; Name = 'Polish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ps'; Name = 'Pashto'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pt'; Name = 'Portuguese (Brazil)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'pt-PT'; Name = 'Portuguese (Portugal)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'qu'; Name = 'Quechua'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'rn'; Name = 'Rundi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ro'; Name = 'Romanian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'rom'; Name = 'Romani'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ru'; Name = 'Russian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'rw'; Name = 'Kinyarwanda'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sa'; Name = 'Sanskrit'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sah'; Name = 'Yakut'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sat'; Name = 'Santali (Ol Chiki)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sat-Lat'; Name = 'Santali (Latin)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'scn'; Name = 'Sicilian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sd'; Name = 'Sindhi'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'se'; Name = 'Sami (North)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sg'; Name = 'Sango'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'shn'; Name = 'Shan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'si'; Name = 'Sinhala'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sk'; Name = 'Slovak'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sl'; Name = 'Slovenian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sm'; Name = 'Samoan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sn'; Name = 'Shona'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'so'; Name = 'Somali'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sq'; Name = 'Albanian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sr'; Name = 'Serbian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ss'; Name = 'Swati'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'st'; Name = 'Sesotho'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'su'; Name = 'Sundanese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sus'; Name = 'Susu'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sv'; Name = 'Swedish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'sw'; Name = 'Swahili'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'szl'; Name = 'Silesian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ta'; Name = 'Tamil'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tcy'; Name = 'Tulu'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'te'; Name = 'Telugu'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tet'; Name = 'Tetum'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tg'; Name = 'Tajik'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'th'; Name = 'Thai'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ti'; Name = 'Tigrinya'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tiv'; Name = 'Tiv'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tk'; Name = 'Turkmen'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tl'; Name = 'Filipino'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tn'; Name = 'Tswana'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'to'; Name = 'Tongan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tpi'; Name = 'Tok Pisin'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tr'; Name = 'Turkish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'trp'; Name = 'Kokborok'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ts'; Name = 'Tsonga'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tt'; Name = 'Tatar'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tum'; Name = 'Tumbuka'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ty'; Name = 'Tahitian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'tyv'; Name = 'Tuvan'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'udm'; Name = 'Udmurt'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ug'; Name = 'Uyghur'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'uk'; Name = 'Ukrainian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'ur'; Name = 'Urdu'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'uz'; Name = 'Uzbek'; Type = 'Both' }
    [PSCustomObject]@{ Code = 've'; Name = 'Venda'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'vec'; Name = 'Venetian'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'vi'; Name = 'Vietnamese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'war'; Name = 'Waray'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'wo'; Name = 'Wolof'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'xh'; Name = 'Xhosa'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'yi'; Name = 'Yiddish'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'yo'; Name = 'Yoruba'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'yua'; Name = 'Yucatec Maya'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'yue'; Name = 'Cantonese'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'zap'; Name = 'Zapotec'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'zh-CN'; Name = 'Chinese (Simplified)'; Type = 'Both' }
    [PSCustomObject]@{ Code = 'zh-TW'; Name = 'Chinese (Traditional)'; Type = 'Target' }
    [PSCustomObject]@{ Code = 'zu'; Name = 'Zulu'; Type = 'Both' }
)



Register-ArgumentCompleter -CommandName 'Get-GoogleTranslateSupportedLanguage' -ParameterName 'TargetLanguageCode' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if ($null -eq $script:GoogleLanguagesCache) {
        $script:GoogleLanguagesCache = $script:FallbackLanguages
    }

    $script:GoogleLanguagesCache | Where-Object { 
        $_.Code -like "$wordToComplete*" -or $_.Name -like "$wordToComplete*" 
    } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Code, 
            "$($_.Code) ($($_.Name))", 
            'ParameterValue', 
            $_.Name
        )
    }
}
