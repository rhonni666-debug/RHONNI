import {createFileRoute} from '@tanstack/react-router';
export const Route=createFileRoute('/redefinir-senha')({component:Page});
function Page(){return <main className="min-h-screen grid place-items-center p-4"><section className="card max-w-md"><h1 className="text-xl font-semibold">Redefinição de acesso</h1><p className="muted">Use o link de recuperação enviado pelo sistema. A atualização segura da credencial permanece no fluxo de autenticação do Supabase.</p><a className="btn mt-3" href="/auth">Voltar para entrar</a></section></main>}
