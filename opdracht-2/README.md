# Opdracht 2 - Gebruik van Ansible Galaxy roles

In deze opdracht worden de eerder gemaakte Ansible roles niet direct lokaal uit de `roles/` map gebruikt, maar opgehaald via een `requirements.yml` bestand. De roles staan in aparte GitHub repositories en kunnen met `ansible-galaxy` worden geïnstalleerd.

## Gebruikte roles

Deze opdracht gebruikt twee roles:

- `webserver`
  - installeert Apache
  - installeert PHP
  - installeert php-mysql
  - plaatst een eenvoudige PHP testpagina

- `database`
  - installeert MySQL
  - configureert de MySQL service
  - maakt een databasegebruiker aan

## Bestanden

```text
opdracht-2/
├── README.md
├── requirements.yml
└── playbook.yml