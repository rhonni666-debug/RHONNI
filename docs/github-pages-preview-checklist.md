# Checklist de validação do preview

- Build normal continua passando no CI existente.
- Build estático com `STATIC_PREVIEW=true` gera `dist/client/_shell.html`.
- O shell é copiado para `index.html` e `404.html`.
- Assets são gerados com base `/RHONNI/`.
- O roteador usa `/RHONNI` como basepath somente no preview estático.
- Login, cadastro e recuperação apontam para callbacks dentro do mesmo subcaminho.
- O preview usa apenas a chave publicável do Supabase; nenhuma chave administrativa é incluída.
