#
# Types.ps1
#
# Copyright © 2020 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#

Add-Type -TypeDefinition @"
public enum DataverseType {
    Sun,
    Mon,
    Tue,
    Wed,
    Thr,
    Fri,
    Sat
}
"@