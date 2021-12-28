#
# Types.ps1
#
# Copyright © 2020 - 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


# Possible values for built-in keyword vocabularies.
Add-Type -TypeDefinition @"
public enum KeywordVocabulary {
    Gnd,
    Lcsh,
    Mesh,
}
"@
