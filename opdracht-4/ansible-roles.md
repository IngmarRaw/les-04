# Inzet van Ansible roles in mijn eigen werk

## Toepassing in mijn eigen werk

In mijn eigen werk zouden Ansible roles vooral nuttig zijn bij werkzaamheden die vaak terugkomen bij verschillende klanten. Omdat wij veel Microsoft-gebaseerde omgevingen beheren, zou de meeste waarde zitten in Windows Server- en Azure-gerelateerde roles.

Een concreet voorbeeld is het uitrollen van een monitoring agent op Windows Servers. Dit gebeurt bij veel klanten op ongeveer dezelfde manier, maar met kleine verschillen zoals klantnaam, monitoringserver of omgevingstype. Door hiervoor een role te gebruiken, kan deze taak sneller en consistenter worden uitgevoerd.

Een ander voorbeeld is het inrichten van een fileserver. Bij meerdere klanten moeten shares, rechten en mappenstructuren worden aangemaakt. Met een Ansible role kan dit reproduceerbaar worden gemaakt en kan de configuratie in Git worden bijgehouden.

## Voordelen

Het gebruik van Ansible roles binnen onze organisatie heeft meerdere voordelen:

### Standaardisatie

Klantomgevingen kunnen op een consistente manier worden ingericht.

### Herbruikbaarheid

Een role kan bij meerdere klanten worden toegepast met andere variabelen.

### Minder handmatig werk

Terugkerende beheertaken kunnen worden geautomatiseerd.

### Minder kans op fouten

Handmatige configuratie leidt sneller tot verschillen of typefouten.

### Versiebeheer

Configuraties staan in Git, waardoor wijzigingen traceerbaar zijn.

### Snellere onboarding van klanten

Nieuwe klantomgevingen kunnen sneller volgens een standaard worden ingericht.

### Betere overdraagbaarheid

Collega’s kunnen zien hoe een configuratie is opgebouwd en dezelfde roles gebruiken.

## Consequenties en aandachtspunten

### Windowsbeheer vereist extra inrichting

Omdat onze omgevingen vooral Microsoft-gebaseerd zijn, moet Ansible goed worden ingericht voor Windowsbeheer. Hiervoor is WinRM nodig. Dat betekent dat op Windows Servers WinRM bereikbaar en veilig geconfigureerd moet zijn.

Daarbij moet rekening worden gehouden met:

- authenticatie
- firewallregels
- certificaten of veilige transportinstellingen
- rechten van het beheeraccount

### Secrets moeten veilig worden opgeslagen

Wachtwoorden, API keys en service account credentials mogen niet plaintext in playbooks of roles staan. Hiervoor moet gebruik worden gemaakt van bijvoorbeeld Ansible Vault of een centrale secrets manager.

Voorbeelden van gevoelige gegevens:

- service account wachtwoorden
- lokale administrator wachtwoorden
- API tokens
- certificaatwachtwoorden
- databasewachtwoorden

### Rollen moeten goed getest worden

Een fout in een role kan impact hebben op meerdere klantservers. Daarom moeten roles eerst getest worden in een labomgeving voordat ze bij klanten worden toegepast.

Een veilige werkwijze is:

1. testen in een lab
2. uitvoeren op één testserver
3. uitvoeren op een kleine servergroep
4. daarna pas breder uitrollen

### Verschillen tussen klanten

Niet elke klant gebruikt dezelfde inrichting. Variabelen zijn daarom belangrijk. Klantspecifieke verschillen kunnen worden vastgelegd in inventory variables of group_vars.

Bijvoorbeeld:

```yaml
customer_name: klant_a
monitoring_server: mon01.klant-a.local
timezone: W. Europe Standard Time