#
# Types.ps1
#
# Copyright © 2020 - 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


# Make sure that WebRequestMethod is available.
Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility


# Possible values for built-in keyword vocabularies.
Add-Type -TypeDefinition @"
public enum KeywordVocabulary {
    Lcsh,
    Mesh,
}
"@
