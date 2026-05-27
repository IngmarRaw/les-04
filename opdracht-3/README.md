# Opdracht 3 - Gebruik van Galaxy roles van een collega

In deze opdracht wordt gebruikgemaakt van Ansible Galaxy roles die door een collega beschikbaar zijn gemaakt. De roles worden via `requirements.yml` geïnstalleerd en daarna gebruikt in een playbook.

## Gebruikte Galaxy roles

Deze opdracht gebruikt de volgende roles:

- `DirectLogic.webserver`
  - configureert de webserver
- `DirectLogic.database`
  - configureert de databaseserver

## Bestanden

```text
opdracht-3/
├── README.md
├── requirements.yml
└── playbook.yml