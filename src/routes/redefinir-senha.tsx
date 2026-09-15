import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';

export const Route = createFileRoute('/redefinir-senha')({
  ssr: false,
  component: RedefinirSenha,
});

type Estado = 'verificando' | 'pronto' | 'invalido';

function RedefinirSenha() {
  const navigate = useNavigate();
  const [estado, setEstado] = useState<Estado>('verificando');
  const [senha, setSenha] = useState('');
  const [confirmar, setConfirmar] = useState('');
  const [ocupado, setOcupado] = useState(false);

  useEffect(() => {
    let ativo = true;
    let timeout: ReturnType<typeof setTimeout> | undefined;

    const { data: listener } = supabase.auth.onAuthStateChange((evento, sessao) => {
      if (!ativo) return;
      if (evento === 'PASSWORD_RECOVERY' || sessao) {
        if (timeout) clearTimeout(timeout);
        setEstado('pronto');
      }
    });

    void (async () => {
      const codigo = new URL(window.location.href).searchParams.get('code');
      if (codigo) {
        const { error } = await supabase.auth.exchangeCodeForSession(codigo);
        if (error && ativo) {
          setEstado('invalido');
          return;
        }
      }

      const { data, error } = await supabase.auth.getSession();
      if (!ativo) return;
      if (!error && data.session) {
        setEstado('pronto');
        return;
      }

      timeout = setTimeout(() => {
        if (ativo) setEstado('invalido');
      }, 2000);
    })();

    return () => {
      ativo = false;
      if (timeout) clearTimeout(timeout);
      listener.subscription.unsubscribe();
    };
  }, []);

  async function salvar(evento: React.FormEvent) {
    evento.preventDefault();
    if (estado !== 'pronto') return;
    if (senha.length < 6) return toast.error('A senha deve ter pelo menos 6 caracteres.');
    if (senha !== confirmar) return toast.error('As senhas não conferem.');

    setOcupado(true);
    const { error } = await supabase.auth.updateUser({ password: senha });
    setOcupado(false);

    if (error) return toast.error(`Não foi possível atualizar a senha: ${error.message}`);

    toast.success('Senha atualizada com sucesso.');
    navigate({ to: '/painel', replace: true });
  }

  if (estado === 'verificando') {
    return <main className="min-h-screen grid place-items-center p-4"><section className="card max-w-md"><h1 className="text-xl font-semibold">Validando link</h1><p className="muted mt-2">Estamos validando o link de recuperação.</p></section></main>;
  }

  if (estado === 'invalido') {
    return <main className="min-h-screen grid place-items-center p-4"><section className="card max-w-md"><h1 className="text-xl font-semibold">Link inválido ou expirado</h1><p className="muted mt-2">Solicite um novo link de recuperação para redefinir sua senha com segurança.</p><a className="btn mt-4 inline-flex" href="/auth?modo=recuperar">Solicitar novo link</a></section></main>;
  }

  return <main className="min-h-screen grid place-items-center p-4"><form className="card w-full max-w-md" onSubmit={salvar}><h1 className="text-xl font-semibold">Definir nova senha</h1><p className="muted mt-2">Escolha uma nova senha para sua conta.</p><label className="block mt-4"><span className="label">Nova senha</span><input className="input mt-1" type="password" autoComplete="new-password" value={senha} onChange={e=>setSenha(e.target.value)} /></label><label className="block mt-3"><span className="label">Confirmar nova senha</span><input className="input mt-1" type="password" autoComplete="new-password" value={confirmar} onChange={e=>setConfirmar(e.target.value)} /></label><button className="btn w-full mt-4" disabled={ocupado}>{ocupado ? 'Salvando...' : 'Salvar nova senha'}</button></form></main>;
}
