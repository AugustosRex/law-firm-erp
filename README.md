# Advocacia ERP — Gestão Completa de Escritório

Sistema baseado em **Dolibarr ERP/CRM** adaptado para advocacia.

## Módulos disponíveis

| Área | Funcionalidades |
|------|----------------|
| 📋 **Processos** | Projetos com status, tarefas, documentos anexos, prazos |
| 💰 **Financeiro** | Contas a pagar/receber, fluxo de caixa, conciliação bancária |
| 🧾 **Faturamento** | Orçamentos, faturas, honorários, controle de cobrança |
| 👥 **Clientes** | CRM completo: contatos, histórico, categorias (cliente/parte contrária) |
| 📅 **Prazos** | Agenda com alertas, prazos processuais vinculados a processos |
| 👤 **RH** | Colaboradores, ausências/férias, despesas/reembolsos |
| 🔐 **Usuários** | Controle de acesso por módulo, permissões granulares |
| 📊 **Relatórios** | Dashboard financeiro, WIP de processos, produtividade |

## ⚠️ AVISO IMPORTANTE: 90 dias do PostgreSQL grátis

O banco PostgreSQL grátis do Render **expira em 90 dias**. Após isso, os dados são perdidos.

**Antes dos 90 dias, faça UMA destas opções:**

1. **Upgrade** no Render Dashboard: banco PostgreSQL pago ($0.60/mês = ~R$3,50)
2. **Migrar** para Supabase (grátis permanente, 500MB): faça backup via Dolibarr e restaure

## Primeiro acesso

1. Acesse a URL: `https://advocacia-erp.onrender.com`
2. Login padrão: `admin` / `admin`
3. **Troque a senha imediatamente**

## Configuração inicial recomendada

1. Ative os módulos: Projetos, Faturamento, Agenda, RH, CRM
2. Crie categorias de clientes: "Cliente Ativo", "Parte Contrária", "Potencial"
3. Configure os tipos de processos: Cível, Trabalhista, Criminal, Família, Tributário
4. Cadastre usuários da equipe com permissões por área