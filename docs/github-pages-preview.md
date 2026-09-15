# Preview sem créditos via GitHub Pages

Este projeto mantém o build normal do TanStack Start inalterado.

O modo de preview estático é ativado somente quando `STATIC_PREVIEW=true`. Nesse modo:

- o TanStack Start usa SPA mode;
- o Vite usa `/RHONNI/` como base pública;
- o TanStack Router usa o mesmo basepath;
- callbacks do Supabase respeitam o subcaminho do GitHub Pages;
- o shell SPA é copiado para `index.html` e `404.html` para permitir navegação direta em rotas do cliente.

O workflow `pages-preview` valida o build em pull requests e, após merge em `main`, tenta publicar `dist/client` no GitHub Pages.

O preview usa somente a URL e a chave publicável do Supabase. Nenhuma service role key ou segredo de servidor é versionado.
