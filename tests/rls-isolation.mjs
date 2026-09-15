import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

assert(url, 'SUPABASE_URL não definido');
assert(anonKey, 'SUPABASE_ANON_KEY não definido');
assert(serviceRoleKey, 'SUPABASE_SERVICE_ROLE_KEY não definido');

const authOptions = { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false };
const admin = createClient(url, serviceRoleKey, { auth: authOptions });
const clientA = createClient(url, anonKey, { auth: authOptions });
const clientB = createClient(url, anonKey, { auth: authOptions });
const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
const password = `RasTest-${stamp}-A9!`;
const emailA = `rls-a-${stamp}@example.test`;
const emailB = `rls-b-${stamp}@example.test`;
let userA;
let userB;

async function createUser(email, nome) {
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { nome },
  });
  assert.equal(error, null, `Falha ao criar ${email}: ${error?.message}`);
  assert(data.user, `Usuário não criado: ${email}`);
  return data.user;
}

async function signIn(client, email) {
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  assert.equal(error, null, `Falha ao autenticar ${email}: ${error?.message}`);
  assert(data.session, `Sessão não criada para ${email}`);
}

try {
  userA = await createUser(emailA, 'Conta A - teste RLS');
  userB = await createUser(emailB, 'Conta B - teste RLS');
  await signIn(clientA, emailA);
  await signIn(clientB, emailB);

  const { data: sistemaA, error: sistemaErro } = await clientA
    .from('ras_systems')
    .insert({
      user_id: userA.id,
      nome: `Sistema isolado ${stamp}`,
      especie: 'Litopenaeus vannamei',
    })
    .select('id,user_id,nome')
    .single();
  assert.equal(sistemaErro, null, `Conta A não conseguiu criar sistema: ${sistemaErro?.message}`);
  assert.equal(sistemaA.user_id, userA.id);

  const { data: leituraA, error: leituraErro } = await clientA
    .from('measurements')
    .insert({
      user_id: userA.id,
      system_id: sistemaA.id,
      classificacao: 'MEDIDO',
      ph: 7.5,
      tan_min: 1.5,
      tan_max: 2.5,
    })
    .select('id,user_id,ph,tan_min,tan_max')
    .single();
  assert.equal(leituraErro, null, `Conta A não conseguiu registrar medição: ${leituraErro?.message}`);
  assert.equal(leituraA.user_id, userA.id);

  const { data: sistemasVisiveisB, error: leituraBErro } = await clientB
    .from('ras_systems')
    .select('id,user_id')
    .eq('id', sistemaA.id);
  assert.equal(leituraBErro, null, `Consulta da conta B falhou inesperadamente: ${leituraBErro?.message}`);
  assert.equal(sistemasVisiveisB.length, 0, 'Conta B visualizou sistema da conta A');

  const { data: medicoesVisiveisB, error: medicaoBErro } = await clientB
    .from('measurements')
    .select('id,user_id')
    .eq('id', leituraA.id);
  assert.equal(medicaoBErro, null, `Consulta de medição da conta B falhou inesperadamente: ${medicaoBErro?.message}`);
  assert.equal(medicoesVisiveisB.length, 0, 'Conta B visualizou medição da conta A');

  const { data: perfilAVisivelB, error: perfilBErro } = await clientB
    .from('profiles')
    .select('id')
    .eq('id', userA.id);
  assert.equal(perfilBErro, null, `Consulta de perfil da conta B falhou inesperadamente: ${perfilBErro?.message}`);
  assert.equal(perfilAVisivelB.length, 0, 'Conta B visualizou perfil da conta A');

  const { data: atualizacaoB, error: atualizacaoBErro } = await clientB
    .from('ras_systems')
    .update({ nome: 'ALTERAÇÃO INDEVIDA' })
    .eq('id', sistemaA.id)
    .select('id');
  assert.equal(atualizacaoBErro, null, `UPDATE bloqueado retornou erro inesperado: ${atualizacaoBErro?.message}`);
  assert.equal(atualizacaoB.length, 0, 'Conta B alterou sistema da conta A');

  const { data: exclusaoB, error: exclusaoBErro } = await clientB
    .from('ras_systems')
    .delete()
    .eq('id', sistemaA.id)
    .select('id');
  assert.equal(exclusaoBErro, null, `DELETE bloqueado retornou erro inesperado: ${exclusaoBErro?.message}`);
  assert.equal(exclusaoB.length, 0, 'Conta B excluiu sistema da conta A');

  const { error: intrusaoErro } = await clientB.from('ras_systems').insert({
    user_id: userA.id,
    nome: 'INTRUSÃO',
    especie: 'Litopenaeus vannamei',
  });
  assert(intrusaoErro, 'Conta B conseguiu inserir registro usando user_id da conta A');

  const { data: sistemaAindaExiste, error: verificacaoAErro } = await clientA
    .from('ras_systems')
    .select('id,nome')
    .eq('id', sistemaA.id)
    .single();
  assert.equal(verificacaoAErro, null, `Conta A perdeu acesso ao próprio sistema: ${verificacaoAErro?.message}`);
  assert.equal(sistemaAindaExiste.id, sistemaA.id);

  console.log('RLS E2E OK: duas contas reais do Supabase Auth permaneceram completamente isoladas nos registros testados.');
} finally {
  await clientA.auth.signOut().catch(() => undefined);
  await clientB.auth.signOut().catch(() => undefined);
  if (userA?.id) await admin.auth.admin.deleteUser(userA.id).catch(() => undefined);
  if (userB?.id) await admin.auth.admin.deleteUser(userB.id).catch(() => undefined);
}
