#
# Modulmanifest für das Modul "PowerShellForDataverse"
#
# Generiert von: Christoph Müller
#
# Generiert am: 06.02.2020
#

@{

    # Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
    # RootModule = ''

    # Die Versionsnummer dieses Moduls
    ModuleVersion = '0.1'

    # Unterstützte PSEditions
    # CompatiblePSEditions = @()

    # ID zur eindeutigen Kennzeichnung dieses Moduls
    GUID = 'eee58cd0-1b64-47ad-a9c6-26417bf6029e'

    # Autor dieses Moduls
    Author = 'Christoph Müller'

    # Unternehmen oder Hersteller dieses Moduls
    CompanyName = 'Visualisierungsinstitut der Universität Stuttgart'

    # Urheberrechtserklärung für dieses Modul
    Copyright = 'Copyright © 2020 - 2021 Visualisierungsinstitut der Universität Stuttgart. Alle Rechte vorbehalten.'

    # Beschreibung der von diesem Modul bereitgestellten Funktionen
    Description = 'PowerShell wrapper for Dataverse API'

    # Die für dieses Modul mindestens erforderliche Version des Windows
    # PowerShell-Moduls
    PowerShellVersion = '4.0'

    # Der Name des für dieses Modul erforderlichen Windows PowerShell-Hosts
    # PowerShellHostName = ''

    # Die für dieses Modul mindestens erforderliche Version des Windows
    # PowerShell-Hosts
    # PowerShellHostVersion = ''

    # Die für dieses Modul mindestens erforderliche Microsoft .NET
    # Framework-Version. Diese erforderliche Komponente ist nur für die
    # PowerShell Desktop-Edition gültig.
    # DotNetFrameworkVersion = ''

    # Die für dieses Modul mindestens erforderliche Version der CLR (Common
    # Language Runtime). Diese erforderliche Komponente ist nur für die
    # PowerShell Desktop-Edition gültig.
    # CLRVersion = ''

    # Die für dieses Modul erforderliche Prozessorarchitektur ("Keine", "X86",
    # "Amd64").
    # ProcessorArchitecture = ''

    # Die Module, die vor dem Importieren dieses Moduls in die globale Umgebung
    # geladen werden müssen.
    # RequiredModules = @()

    # Die Assemblys, die vor dem Importieren dieses Moduls geladen werden
    # müssen.
    RequiredAssemblies = @(
        'Microsoft.PowerShell.Commands.Utility'
    )

    # Die Skriptdateien (PS1-Dateien), die vor dem Importieren dieses Moduls in
    # der Umgebung des Aufrufers ausgeführt werden.
    #ScriptsToProcess = @()

    # Die Typdateien (.ps1xml), die beim Importieren dieses Moduls geladen
    # werden sollen.
    # TypesToProcess = @()

    # Die Formatdateien (.ps1xml), die beim Importieren dieses Moduls geladen
    # werden sollen.
    # FormatsToProcess = @()

    # Die Module, die als geschachtelte Module des in
    # "RootModule/ModuleToProcess" angegebenen Moduls importiert werden sollen.
    NestedModules     = @(
        'Request.ps1',  # Must be first!
        'Metadata.ps1',
        'CitationMetadata.ps1',
        'DataSet.ps1',
        'Dataverse.ps1')

    # Aus diesem Modul zu exportierende Funktionen. Um optimale Leistung zu
    # erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht.
    # Verwenden Sie ein leeres Array, wenn keine zu exportierenden Funktionen
    # vorhanden sind.
    FunctionsToExport = @(
        'Add-CitationMetadataAuthor',
        'Add-CitationMetadataKeyword',
        'Add-LinkedDataSet',
        'Add-DataverseRole',
        'Get-ChildDataverse',
        'Get-DataSet',
        'Get-DataSetDescription',
        'Get-DataSetFiles',
        'Get-DataSetVersion',
        'Get-Dataverse',
        'Get-DataverseRole',
        'Get-Metadata',
        'New-DataverseCitationMetadata',
        'New-DataverseDataSetDescriptor',
        'New-DataverseDescriptor',
        'New-DataverseMetadata',
        'New-DataverseMetadataField',
        'New-Dataverse',
        'Remove-Dataverse',
        'Remove-DataverseRole',
        'Remove-LinkedDataSet'
    )

    # Aus diesem Modul zu exportierende Cmdlets. Um optimale Leistung zu
    # erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht.
    # Verwenden Sie ein leeres Array, wenn keine zu exportierenden Cmdlets
    # vorhanden sind.
    CmdletsToExport = @()

    # Die aus diesem Modul zu exportierenden Variablen
    VariablesToExport = '*'

    # Aus diesem Modul zu exportierende Aliase. Um optimale Leistung zu
    # erzielen, verwenden Sie keine Platzhalter und löschen den Eintrag nicht.
    # Verwenden Sie ein leeres Array, wenn keine zu exportierenden Aliase
    # vorhanden sind.
    AliasesToExport = @()

    # Aus diesem Modul zu exportierende DSC-Ressourcen
    # DscResourcesToExport = @()

    # Liste aller Module in diesem Modulpaket
    # ModuleList = @()

    # Liste aller Dateien in diesem Modulpaket
    # FileList = @()

    # Die privaten Daten, die an das in "RootModule/ModuleToProcess" angegebene
    # Modul übergeben werden sollen. Diese können auch eine PSData-Hashtabelle
    # mit zusätzlichen von PowerShell verwendeten Modulmetadaten enthalten.
    PrivateData       = @{

        PSData = @{

            # 'Tags' wurde auf das Modul angewendet und unterstützt die
            # Modulermittlung in Onlinekatalogen.
            Tags = @( 'Dataverse', 'API', 'PowerShell' )

            # Eine URL zur Lizenz für dieses Modul.
            # LicenseUri = ''

            # Eine URL zur Hauptwebsite für dieses Projekt.
            # ProjectUri = ''

            # Eine URL zu einem Symbol, das das Modul darstellt.
            # IconUri = ''

            # 'ReleaseNotes' des Moduls
            # ReleaseNotes = ''

        } # Ende der PSData-Hashtabelle

    } # Ende der PrivateData-Hashtabelle

    # HelpInfo-URI dieses Moduls
    # HelpInfoURI = ''

    # Standardpräfix für Befehle, die aus diesem Modul exportiert werden. Das
    # Standardpräfix kann mit "Import-Module -Prefix" überschrieben werden.
    # DefaultCommandPrefix = ''

}

