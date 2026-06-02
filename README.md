# Les 04 - Ansible Roles en Ansible Galaxy

## Inleiding

Deze repository bevat de uitwerking van de opdrachten voor les 04. De focus van deze les ligt op het gebruik van Ansible roles, het structureren van configuratiebeheer en het hergebruiken van roles via Ansible Galaxy.

In deze repository is gewerkt met een combinatie van Terraform en Ansible. Terraform wordt gebruikt voor het uitrollen van virtuele machines op ESXi. Ansible wordt gebruikt voor het configureren van deze machines. Hierbij is gebruikgemaakt van inventories, group variables, roles, handlers, metadata en Ansible Vault.

De opdrachten zijn verdeeld over meerdere mappen, zodat elke opdracht afzonderlijk te bekijken en uit te voeren is.

## Repositorystructuur

```text
les-04/
├── README.md
├── opdracht-1/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── cloudinit.tftpl
│   └── ansible/
│       ├── ansible.cfg
│       ├── inventory.ini
│       ├── playbook.yml
│       ├── group_vars/
│       │   ├── all/
│       │   │   └── vault.yml
│       │   ├── esxi.yml
│       │   ├── webservers.yml
│       │   └── databaseservers.yml
│       └── roles/
│           ├── webserver/
│           │   ├── tasks/
│           │   │   └── main.yml
│           │   ├── handlers/
│           │   │   └── main.yml
│           │   └── meta/
│           │       └── main.yml
│           └── database/
│               ├── tasks/
│               │   └── main.yml
│               ├── handlers/
│               │   └── main.yml
│               └── meta/
│                   └── main.yml
├── opdracht-2/
│   ├── README.md
│   ├── requirements.yml
│   └── playbook.yml
└── opdracht-3/
    ├── README.md
    ├── requirements.yml
    ├── playbook.yml
    └── ansible_roles_in_organisatie.md
```

---

# Opdracht 1 - Terraform deployment en Ansible configuratie

## Doel

In opdracht 1 worden met Terraform twee VM’s uitgerold op ESXi:

- één webserver
- één databaseserver

Na het deployen wordt automatisch een Ansible inventory aangemaakt. Vervolgens wordt Ansible gebruikt om de servers te configureren.

De webserver wordt ingericht met:

- Apache
- PHP
- php-mysql

De databaseserver wordt ingericht met:

- MySQL
- een databasegebruiker `dbuser`

De databasegegevens worden niet plaintext in het playbook gezet, maar opgeslagen met Ansible Vault.

---

## Terraform

Terraform staat in:

```text
opdracht-1/terraform/
```

Terraform maakt de VM’s aan op ESXi en zorgt ervoor dat de juiste hostnamen en IP-adressen automatisch in een Ansible inventorybestand terechtkomen.

De inventory wordt gegenereerd in:

```text
opdracht-1/ansible/inventory.ini
```

Hierdoor hoeft de inventory niet handmatig bijgewerkt te worden wanneer de IP-adressen van de VM’s veranderen.

---

## ESXi-configuratie

De ESXi-hostgegevens zijn niet direct in `terraform.tfvars` geplaatst. In plaats daarvan worden de niet-gevoelige ESXi-gegevens vanuit een `group_vars` bestand gelezen:

```text
opdracht-1/ansible/group_vars/esxi.yml
```

Hiervoor is gekozen omdat dit netter is dan het hardcoden van het ESXi IP-adres in `terraform.tfvars`.

Voorbeeld van de ESXi-configuratie:

```yaml
esxi_hostname: "192.168.2.150"
esxi_hostport: 22
esxi_hostssl: 443
esxi_username: "root"
```

Het ESXi-wachtwoord wordt niet in Git geplaatst. Dit kan bijvoorbeeld via een environment variable worden meegegeven:

```bash
export TF_VAR_esxi_password='wachtwoord'
```

---

## SSH-key pad

Voor de SSH-key wordt gebruikgemaakt van:

```text
~/.ssh/id_ed25519.pub
```

Dit is netter dan een absoluut pad waarin bijvoorbeeld een gebruikersnaam of studentnummer staat. Terraform gebruikt `pathexpand()` waar nodig om dit pad correct te verwerken.

Voor de gegenereerde Ansible inventory wordt het pad bewust leesbaar gehouden als:

```text
~/.ssh/id_ed25519
```

Hierdoor komt er geen gebruikersnaam of studentnummer in het inventorybestand terecht.

---

## Cloud-init

De VM’s worden via cloud-init voorzien van een gebruiker en SSH-toegang.

Voorbeeld:

```yaml
#cloud-config
users:
  - name: ${username}
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - ${ssh_public_key}

package_update: true
packages:
  - python3
  - python3-apt
```

Hiermee wordt automatisch een gebruiker aangemaakt met sudo-rechten zonder wachtwoordprompt. Ook wordt de public SSH-key geplaatst, zodat Ansible via SSH kan verbinden.

---

## Automatisch gegenereerde inventory

Terraform maakt automatisch een inventory aan voor Ansible. De inventory bevat groepen voor de webserver en databaseserver.

Voorbeeld:

```ini
[webservers]
les04-webserver ansible_host=192.168.2.140 ansible_user=iacuser ansible_ssh_private_key_file=~/.ssh/id_ed25519

[databaseservers]
les04-database ansible_host=192.168.2.141 ansible_user=iacuser ansible_ssh_private_key_file=~/.ssh/id_ed25519

[esxi:children]
webservers
databaseservers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Hiermee is duidelijk welke VM de webserver is en welke VM de databaseserver is.

---

## Terraform outputs

Er is een `outputs.tf` toegevoegd. Hiermee worden belangrijke waarden na een deployment overzichtelijk getoond.

De outputs bevatten:

- naam van de webserver VM
- IP-adres van de webserver VM
- naam van de databaseserver VM
- IP-adres van de databaseserver VM
- pad naar de gegenereerde Ansible inventory

De outputs kunnen worden bekeken met:

```bash
terraform output
```

Deze toevoeging maakt het makkelijker om na een deployment snel te controleren welke VM’s zijn aangemaakt en welke IP-adressen zijn toegewezen.

---

## Ansible

Ansible staat in:

```text
opdracht-1/ansible/
```

De configuratie is opgebouwd met roles:

```text
roles/
├── webserver/
└── database/
```

De webserver role installeert Apache, PHP en php-mysql.

De database role installeert MySQL, maakt een applicatiedatabase aan en maakt een databasegebruiker aan.

Er wordt gebruikgemaakt van:

- inventory groups
- group_vars
- roles
- handlers
- Ansible Vault
- role metadata

Alle YAML-bestanden, waaronder het playbook, starten met `---` voor consistente YAML-opmaak.

---

## Group variables

Voor de webservers en databaseservers worden aparte `group_vars` gebruikt.

Voorbeeld voor webservers:

```yaml
---
apache_package: apache2

php_packages:
  - php
  - php-mysql

web_service_name: apache2
web_document_root: /var/www/html
web_index_file: index.php
```

Voorbeeld voor databaseservers:

```yaml
---
mysql_package: mysql-server
mysql_service_name: mysql
mysql_python_package: python3-pymysql
mysql_bind_address: "0.0.0.0"
mysql_database_name: les04db
mysql_user_privileges: "{{ mysql_database_name }}.*:ALL"
mysql_user_host: "{{ hostvars[groups['webservers'][0]].ansible_host }}"
```

Hierdoor staan configuratiewaarden niet hardcoded in de tasks, maar netjes gescheiden in variabelenbestanden.

---

## Ansible Vault

De databasegegevens staan niet plaintext in het playbook. Hiervoor wordt Ansible Vault gebruikt.

Het vaultbestand staat in:

```text
opdracht-1/ansible/group_vars/all/vault.yml
```

In dit bestand staan versleuteld de databasevariabelen:

```yaml
---
mysql_user_name: dbuser
mysql_user_password: dbpassword
```

Het playbook kan worden uitgevoerd met:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

De reden hiervoor is dat wachtwoorden en andere gevoelige gegevens niet leesbaar in Git of in gewone YAML-bestanden horen te staan.

Belangrijk is dat de database credentials niet meer als plaintext `vars` in de playbooks staan. Hierdoor krijgen de waarden uit `group_vars/all/vault.yml` daadwerkelijk effect.

---

## MySQL-rechten

Voor de opdracht zou een brede configuratie zoals onderstaande technisch werken:

```yaml
mysql_user_host: "%"
priv: "*.*:ALL"
```

Dit is echter ruimer dan nodig. Daarom is de configuratie aangescherpt.

De databasegebruiker krijgt alleen rechten op de specifieke applicatiedatabase:

```yaml
mysql_database_name: les04db
mysql_user_privileges: "{{ mysql_database_name }}.*:ALL"
```

Daarnaast wordt de databasegebruiker beperkt tot de webserverhost:

```yaml
mysql_user_host: "{{ hostvars[groups['webservers'][0]].ansible_host }}"
```

Hierdoor krijgt de gebruiker alleen toegang vanaf de webserver en niet vanaf elke host.

---

## Bescherming van gevoelige output

De task die de MySQL-gebruiker aanmaakt gebruikt:

```yaml
no_log: true
```

Hierdoor worden gevoelige waarden, zoals het databasewachtwoord, niet zichtbaar in de Ansible-output.

Dit is belangrijk omdat Ansible-output vaak wordt opgeslagen in terminals, logbestanden of CI/CD-systemen.

---

## `column_case_sensitive`

In de MySQL user task is `column_case_sensitive: true` opgenomen bij de `community.mysql.mysql_user` module.

Dit is toegevoegd om expliciet gedrag vast te leggen en waarschuwingen over veranderende defaults in de `community.mysql` collection te voorkomen.

---

## Handlers

In de roles worden handlers gebruikt om services opnieuw te starten wanneer configuratie of packages wijzigen.

Voorbeelden:

- Apache wordt herstart na wijzigingen aan de webserverconfiguratie.
- MySQL wordt herstart na wijzigingen aan de databaseconfiguratie.

Dit voorkomt onnodige service restarts en sluit beter aan bij Ansible best practices.

---

## Role metadata

De roles bevatten een `meta/main.yml`. Hierin staat metadata zoals:

- auteur
- beschrijving
- platform
- minimale Ansible-versie
- tags
- dependencies

Dit is toegevoegd omdat dit aansluit bij de structuur die ook door Ansible Galaxy wordt verwacht.

De database role metadata is specifiek aangepast voor de database role. De beschrijving en tags verwijzen naar MySQL/database en niet naar Apache/PHP/webserver.

---

## Uitvoeren van opdracht 1

### Terraform uitvoeren

Ga naar de Terraform-map:

```bash
cd opdracht-1/terraform
```

Zet indien nodig het ESXi-wachtwoord als environment variable:

```bash
export TF_VAR_esxi_password='wachtwoord'
```

Voer Terraform uit:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Controleer daarna de gegenereerde inventory:

```bash
cat ../ansible/inventory.ini
```

Controleer de Terraform outputs:

```bash
terraform output
```

### Ansible uitvoeren

Ga naar de Ansible-map:

```bash
cd ../ansible
```

Test de verbinding:

```bash
ansible all -m ping --ask-vault-pass
```

Voer het playbook uit:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

Controleer de services:

```bash
ansible webservers -m shell -a "systemctl is-active apache2" --ask-vault-pass
ansible databaseservers -m shell -a "systemctl is-active mysql" --ask-vault-pass
```

---

# Opdracht 2 - Eigen roles gebruiken via Ansible Galaxy/GitHub

## Doel

In opdracht 2 zijn de roles uit opdracht 1 losgetrokken en beschikbaar gemaakt als herbruikbare roles. Hiervoor zijn aparte GitHub repositories gebruikt:

```text
IngmarRaw/ansible-role-webserver
IngmarRaw/ansible-role-database
```

Het doel hiervan is om de roles niet alleen lokaal in één project te gebruiken, maar als herbruikbare bouwblokken beschikbaar te maken.

---

## Redenering

In een professionele omgeving is het logisch om generieke roles apart te beheren. Een webserver role of database role kan dan in meerdere projecten worden gebruikt. Hierdoor voorkom je dat dezelfde configuratie op meerdere plekken gekopieerd wordt.

Door de roles in aparte repositories te zetten, kunnen ze onafhankelijk worden beheerd, verbeterd en opnieuw gebruikt.

---

## Bestanden

Opdracht 2 bevat:

```text
opdracht-2/
├── README.md
├── requirements.yml
└── playbook.yml
```

In `requirements.yml` staan de externe roles die geïnstalleerd moeten worden.

Voorbeeld:

```yaml
---
roles:
  - name: webserver
    src: https://github.com/IngmarRaw/ansible-role-webserver.git
    scm: git

  - name: database
    src: https://github.com/IngmarRaw/ansible-role-database.git
    scm: git

collections:
  - name: community.mysql
```

---

## Vault in opdracht 2

De database credentials staan niet plaintext in het playbook van opdracht 2. In plaats daarvan wordt de Vault uit opdracht 1 hergebruikt.

Het playbook wordt uitgevoerd met:

```bash
ansible-playbook -i ../opdracht-1/ansible/inventory.ini playbook.yml \
  -e @../opdracht-1/ansible/group_vars/all/vault.yml \
  --ask-vault-pass
```

Hierdoor worden de versleutelde variabelen uit opdracht 1 geladen en blijft het playbook zelf vrij van plaintext wachtwoorden.

---

## Roles installeren

De roles kunnen worden geïnstalleerd met:

```bash
ansible-galaxy install -r requirements.yml -p roles
```

Eventuele collections kunnen worden geïnstalleerd met:

```bash
ansible-galaxy collection install -r requirements.yml
```

---

## Playbook uitvoeren

Het playbook gebruikt de inventory uit opdracht 1:

```bash
ansible-playbook -i ../opdracht-1/ansible/inventory.ini playbook.yml \
  -e @../opdracht-1/ansible/group_vars/all/vault.yml \
  --ask-vault-pass
```

---

## Waarom een requirements.yml?

Met `requirements.yml` kan worden vastgelegd welke externe roles en collections nodig zijn. Hierdoor hoeft een gebruiker niet handmatig roles te downloaden. De benodigde dependencies kunnen met één commando worden geïnstalleerd.

Dit maakt de opdracht beter reproduceerbaar.

---

# Opdracht 3 - Gebruik van roles van een collega

## Doel

In opdracht 3 wordt gebruikgemaakt van Ansible Galaxy roles van een collega:

```text
DirectLogic.webserver
DirectLogic.database
```

Hiermee wordt aangetoond dat roles niet alleen zelf gemaakt kunnen worden, maar ook door anderen gedeeld en hergebruikt kunnen worden.

---

## Bestanden

Opdracht 3 bevat:

```text
opdracht-3/
├── README.md
├── requirements.yml
├── playbook.yml
└── ansible_roles_in_organisatie.md
```

---

## Redenering

Het gebruik van externe roles is nuttig omdat het hergebruik stimuleert. In plaats van zelf alle configuratie opnieuw te schrijven, kan een bestaande role worden gebruikt. Dit lijkt op hoe modules of packages in andere programmeer- en beheeromgevingen worden hergebruikt.

Wel is het belangrijk om te controleren wat een externe role precies doet. Een role van een collega of uit Ansible Galaxy kan wijzigingen uitvoeren op systemen. Daarom moet deze eerst worden bekeken en getest voordat hij in een productieomgeving gebruikt wordt.

---

## Requirements

Voorbeeld van `requirements.yml`:

```yaml
---
roles:
  - name: DirectLogic.webserver
  - name: DirectLogic.database
```

---

## Playbook

Het playbook gebruikt de Galaxy roles van de collega en past deze toe op de groepen uit de bestaande inventory.

Voorbeeld:

```yaml
---
- name: Configureer webserver met Galaxy role van collega
  hosts: webservers
  become: true

  roles:
    - DirectLogic.webserver

- name: Configureer databaseserver met Galaxy role van collega
  hosts: databaseservers
  become: true

  roles:
    - DirectLogic.database
```

Ook hier staan database credentials niet plaintext in het playbook. Indien de gebruikte role databasevariabelen nodig heeft, worden deze via Vault of veilige variabelen meegegeven.

---

## Roles installeren

De roles worden geïnstalleerd met:

```bash
ansible-galaxy install -r requirements.yml -p roles
```

Als er collections nodig zijn:

```bash
ansible-galaxy collection install -r requirements.yml
```

---

## Playbook uitvoeren

Het playbook gebruikt opnieuw de inventory uit opdracht 1 en kan de Vault uit opdracht 1 hergebruiken:

```bash
ansible-playbook -i ../opdracht-1/ansible/inventory.ini playbook.yml \
  -e @../opdracht-1/ansible/group_vars/all/vault.yml \
  --ask-vault-pass
```

---

# Reflectie - Ansible roles in mijn eigen werk

## Toepassing in mijn eigen werk

In mijn eigen werk zouden Ansible roles vooral nuttig zijn bij werkzaamheden die vaak terugkomen bij verschillende klanten. Omdat wij veel Microsoft-gebaseerde omgevingen beheren, zou de meeste waarde zitten in Windows Server- en Azure-gerelateerde roles.

Een concreet voorbeeld is het uitrollen van een monitoring agent op Windows Servers. Dit gebeurt bij veel klanten op ongeveer dezelfde manier, maar met kleine verschillen zoals klantnaam, monitoringserver of omgevingstype. Door hiervoor een role te gebruiken, kan deze taak sneller en consistenter worden uitgevoerd.

Een ander voorbeeld is het inrichten van een fileserver. Bij meerdere klanten moeten shares, rechten en mappenstructuren worden aangemaakt. Met een Ansible role kan dit reproduceerbaar worden gemaakt en kan de configuratie in Git worden bijgehouden.

---

## Voordelen

Het gebruik van Ansible roles binnen onze organisatie heeft meerdere voordelen.

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

---

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
```

Voor een andere klant kunnen dezelfde roles worden gebruikt met andere waarden.

### Governance en afspraken

Binnen een beheerorganisatie zijn duidelijke afspraken nodig over:

- naamgeving van roles
- waar roles worden opgeslagen
- wie wijzigingen mag goedkeuren
- hoe code reviews plaatsvinden
- hoe secrets worden beheerd
- hoe wijzigingen worden getest
- hoe productie-uitrol plaatsvindt

---

## Mogelijke repositorystructuur

Een mogelijke structuur voor een interne Ansible repository kan zijn:

```text
ansible-infra/
├── inventories/
│   ├── klant-a/
│   ├── klant-b/
│   └── productie/
├── playbooks/
│   ├── windows-baseline.yml
│   ├── fileservers.yml
│   ├── iis-webservers.yml
│   └── monitoring.yml
├── roles/
│   ├── windows_baseline/
│   ├── active_directory/
│   ├── fileserver/
│   ├── iis_webserver/
│   └── monitoring_agent/
└── group_vars/
    ├── all.yml
    ├── windows_servers.yml
    └── klant_a.yml
```

---

## Conclusie reflectie

Ansible roles kunnen ook in een sterk Microsoft-gebaseerde organisatie waardevol zijn. Hoewel Linux binnen onze organisatie beperkt wordt gebruikt, kunnen roles juist helpen bij het standaardiseren van Windows Server-, Azure- en beheerconfiguraties.

De meeste waarde zit in het automatiseren van terugkerende taken zoals Windows baselines, monitoring agents, fileserverconfiguratie, IIS-configuratie en Active Directory-beheer. Hierdoor wordt beheer consistenter, beter overdraagbaar en minder foutgevoelig.

Belangrijke aandachtspunten zijn wel het veilig inrichten van WinRM, het beschermen van secrets, het goed testen van roles en het maken van duidelijke teamafspraken. Wanneer dit goed wordt ingericht, kunnen Ansible roles een nuttig hulpmiddel zijn voor professioneel beheer van klantomgevingen.

---

# Verwerking feedback

Naar aanleiding van feedback zijn de volgende verbeteringen doorgevoerd:

- `opdracht-1/ansible/playbook.yml` start nu met `---`, net als de andere YAML-bestanden.
- Database credentials zijn uit de playbooks verwijderd en worden via Ansible Vault geladen.
- De Vault-aanpak wordt nu daadwerkelijk toegepast, omdat playbook-vars met plaintext credentials zijn verwijderd.
- De database user task gebruikt `no_log: true`, zodat wachtwoorden niet in Ansible-output verschijnen.
- `column_case_sensitive: true` is bewust behouden bij `community.mysql.mysql_user` om expliciet gedrag vast te leggen.
- De metadata van de database role is gecorrigeerd en verwijst nu naar MySQL/database in plaats van Apache/PHP/webserver.
- Er is een `outputs.tf` toegevoegd voor VM-namen, IP-adressen en het inventory-pad.
- MySQL-rechten zijn aangescherpt van `*.*:ALL` naar rechten op een specifieke database.
- De MySQL-gebruiker wordt beperkt tot de webserverhost in plaats van toegang vanaf elke host.

---

# Belangrijke keuzes

## Waarom Terraform en Ansible combineren?

Terraform is gebruikt voor het aanmaken van de infrastructuur. Ansible is gebruikt voor de configuratie binnen de VM’s.

Dit zorgt voor een duidelijke scheiding:

- Terraform: infrastructuur aanmaken
- Ansible: servers configureren

Deze scheiding maakt de omgeving overzichtelijker en beter onderhoudbaar.

---

## Waarom automatisch een inventory genereren?

De IP-adressen van VM’s kunnen veranderen. Door de inventory automatisch met Terraform te laten genereren, hoeft deze niet handmatig bijgewerkt te worden.

Dit voorkomt fouten en maakt de omgeving reproduceerbaar.

---

## Waarom roles gebruiken?

Roles maken Ansible-code overzichtelijker en herbruikbaar. In plaats van alle taken in één groot playbook te zetten, worden taken logisch gegroepeerd per functie.

Voorbeelden:

- webserver role
- database role

Roles maken het ook makkelijker om configuratie later opnieuw te gebruiken in andere opdrachten of projecten.

---

## Waarom Ansible Vault gebruiken?

Databasewachtwoorden en andere gevoelige gegevens horen niet plaintext in playbooks of Git te staan. Met Ansible Vault kunnen deze waarden versleuteld worden opgeslagen.

Hierdoor blijft de configuratie bruikbaar, maar worden gevoelige gegevens beter beschermd.

---

## Waarom Galaxy roles?

Ansible Galaxy maakt het mogelijk om roles te delen en opnieuw te gebruiken. Hierdoor kunnen roles uit aparte repositories worden opgehaald en in andere projecten worden gebruikt.

Dit sluit aan op professioneel werken, omdat herbruikbare componenten los beheerd kunnen worden van de projectrepository.

---

# Git en gevoelige bestanden

Niet alle bestanden horen in Git. Bestanden zoals Terraform state, lokale inventories en secrets moeten worden genegeerd.

Voorbeelden van bestanden die niet in Git horen:

```text
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
inventory.ini
*.retry
.DS_Store
```

Hiervoor wordt een `.gitignore` gebruikt.

---

# Algemene conclusie

In deze les is gewerkt met Terraform, Ansible roles en Ansible Galaxy. De opdrachten laten zien hoe infrastructuur kan worden uitgerold, hoe servers automatisch kunnen worden geconfigureerd en hoe roles herbruikbaar gemaakt kunnen worden.

De belangrijkste leerpunten zijn:

- Terraform kan gebruikt worden om VM’s te deployen.
- Terraform kan automatisch een Ansible inventory genereren.
- Terraform outputs maken belangrijke deploymentinformatie zichtbaar.
- Ansible roles zorgen voor structuur en herbruikbaarheid.
- Handlers zorgen voor nette service restarts.
- `meta/main.yml` maakt roles completer en beter geschikt voor Galaxy.
- Ansible Vault voorkomt plaintext secrets.
- `no_log: true` voorkomt dat gevoelige waarden in Ansible-output verschijnen.
- Ansible Galaxy maakt het mogelijk om roles te delen en opnieuw te gebruiken.
- Externe roles moeten altijd gecontroleerd worden voordat ze worden toegepast.

Deze aanpak sluit aan bij professioneel infrastructuurbeheer, waarbij configuratie zoveel mogelijk als code wordt beheerd en herbruikbaarheid, veiligheid en consistentie belangrijk zijn.