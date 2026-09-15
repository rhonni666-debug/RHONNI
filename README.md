# RAS Digital Twin

V1 operacional para monitoramento experimental de Litopenaeus vannamei em RAS.

## Stack
React + TypeScript + TanStack Start + Supabase/PostgreSQL + RLS.

## Regras científicas essenciais
- ausência de leitura = SEM MEDIÇÃO; zero é um valor real;
- TAN colorimétrico preserva mínimo/máximo;
- dados medidos não são misturados com estimativas/previsões;
- estoque planejado não cria população real;
- gêmeo digital não prevê sem dados suficientes para calibração.

## Ambiente
Copie `.env.example` para `.env` e configure as variáveis via ambiente. Nunca versione `.env`.

## Desenvolvimento
`npm install` e `npm run dev`.
