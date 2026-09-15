import {createFileRoute} from '@tanstack/react-router';
import {useEffect,useState} from 'react';
import {toast} from 'sonner';
import {supabase} from '@/integrations/supabase/client';
import {useSelection} from '@/lib/selection';

export const Route=createFileRoute('/_authenticated/perfil')({component:Page});
function Page(){
 const {userId}=useSelection(); const [name,setName]=useState('');
 useEffect(()=>{void supabase.from('profiles').select('nome').eq('id',userId).maybeSingle().then(({data})=>setName(data?.nome??''));},[userId]);
 async function save(e:React.FormEvent){e.preventDefault();const {error}=await supabase.from('profiles').update({nome:name.trim()}).eq('id',userId);if(error)return toast.error(error.message);toast.success('Perfil atualizado.');}
 return <section className="max-w-xl"><div className="label">Sistema</div><h1 className="text-2xl font-semibold">Perfil</h1><form className="card mt-4" onSubmit={save}><label><span className="label">Nome</span><input className="input mt-1" value={name} onChange={e=>setName(e.target.value)}/></label><button className="btn mt-4">Salvar perfil</button></form></section>;
}
