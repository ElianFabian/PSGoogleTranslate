# PSGoogleTranslate

<h3>A PowerShell module to easily use the free Google Translate API.</h3>

## Functions

The module exports two functions:

- Invoke-GoogleTranslate: performs translation and other language analysis queries.
- Get-GoogleTranslateSupportedLanguage: lists supported languages and enables tab-completion for the translate function.

## Basic usage

Translate a string by providing the input text and the source/target language codes:

```powershell
Invoke-GoogleTranslate -InputObject "Hoy vi un ciervo" -SourceLanguageCode es -TargetLanguageCode en
```

Example output:

```text
SourceLanguage TargetLanguage Translation
-------------- -------------- -----------
es             en             I saw a deer today
```

The default source language is `auto`.

## Discover supported languages

Use the helper function to inspect the available language list. The function also supports `-Refresh` to force a fresh query and caches the result for later use.

```powershell
Get-GoogleTranslateSupportedLanguage -TargetLanguageCode en
```

Each returned object includes:

- Code: the ISO language code
- Name: the localized language name
- Type: `Source`, `Target`, or `Both`

## Return types

The `ReturnType` parameter supports the following values:

- Translation (default): returns the translated text plus language metadata.
- Alternative: returns alternative translations grouped by source line.
- DetectedLanguage: returns the detected source language code.
- Dictionary: returns dictionary entries for a word or phrase.
- Definition: returns word definitions for a single word.
- Synonym: returns synonyms for a single word.
- Example: returns usage examples for a single word.

### Notes

- Definition, Synonym, and Example are intended for single-word input.
- Translation, Alternative, Dictionary, and Example require a target language.
- The underlying API is rate-limited, so responses may be slow and parallel requests are not recommended.

## Extra

The implementation was based on the information from [this guide](https://wiki.freepascal.org/Using_Google_Translate). Some response data may be incomplete or vary depending on the service response.
