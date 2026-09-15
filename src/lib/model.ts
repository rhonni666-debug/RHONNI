export type Sistema = {
  id: string; nome: string; especie: string; volume_cultivo_l: number | null;
  volume_mbbr_l: number | null; volume_decantador_l: number | null;
  volume_hidraulico_total_l: number | null; salinidade_planejada_ppt: number | null;
  estoque_planejado: number | null; observacoes: string | null;
};
export type Experimento = {
  id: string; system_id: string; nome: string; objetivo: string | null; descricao: string | null;
  data_planejada: string | null; observacoes: string | null; status: string; fase: string | null; iniciado_em: string | null;
};
export type Medicao = Record<string, unknown> & {
  id: string; medido_em: string; classificacao: string; tan_min: number | null; tan_max: number | null;
  no2: number | null; no3: number | null; ph: number | null; temperatura: number | null;
  oxigenio_dissolvido: number | null; salinidade: number | null; alcalinidade: number | null;
};
export type Evento = { id: string; tipo: string; ocorrido_em: string; quantidade: number | null; unidade: string | null; descricao: string | null; observacoes: string | null };
export const PARAMETROS = [
  ["tan", "TAN", "mg/L"], ["no2", "NO₂", "mg/L"], ["no3", "NO₃", "mg/L"], ["ph", "pH", ""],
  ["temperatura", "Temperatura", "°C"], ["oxigenio_dissolvido", "Oxigênio dissolvido", "mg/L"],
  ["salinidade", "Salinidade", "ppt"], ["alcalinidade", "Alcalinidade", "mg/L CaCO₃"]
] as const;
export const SEM_MEDICAO = "SEM MEDIÇÃO";
export const fmt = (n: number | null | undefined, d=2) => n == null ? SEM_MEDICAO : new Intl.NumberFormat("pt-BR", {maximumFractionDigits:d}).format(n);
export const fmtDH = (iso: string) => new Date(iso).toLocaleString("pt-BR", {day:"2-digit",month:"2-digit",year:"numeric",hour:"2-digit",minute:"2-digit"});
export const elapsed = (iso: string) => { const m=Math.max(0,Math.floor((Date.now()-new Date(iso).getTime())/60000)); return m<60?`há ${m} min`:m<1440?`há ${Math.floor(m/60)} h`:`há ${Math.floor(m/1440)} d`; };
export const diaExperimental = (iso: string | null) => iso ? Math.max(0, Math.floor((Date.now()-new Date(iso).getTime())/86400000)) : null;
export const tipoEvento = (v:string) => v.toLowerCase().replaceAll("_"," ").replace(/^./,c=>c.toUpperCase());
