CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql SET search_path = public;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  nome TEXT,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "perfil proprio" ON public.profiles FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, nome, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'nome', NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END; $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TABLE public.ras_systems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  nome TEXT NOT NULL,
  especie TEXT NOT NULL DEFAULT 'Litopenaeus vannamei',
  volume_cultivo_l NUMERIC CHECK (volume_cultivo_l IS NULL OR volume_cultivo_l >= 0),
  volume_mbbr_l NUMERIC CHECK (volume_mbbr_l IS NULL OR volume_mbbr_l >= 0),
  volume_decantador_l NUMERIC CHECK (volume_decantador_l IS NULL OR volume_decantador_l >= 0),
  volume_hidraulico_total_l NUMERIC CHECK (volume_hidraulico_total_l IS NULL OR volume_hidraulico_total_l >= 0),
  salinidade_planejada_ppt NUMERIC CHECK (salinidade_planejada_ppt IS NULL OR salinidade_planejada_ppt >= 0),
  estoque_planejado INTEGER CHECK (estoque_planejado IS NULL OR estoque_planejado >= 0),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ras_systems TO authenticated;
GRANT ALL ON public.ras_systems TO service_role;
ALTER TABLE public.ras_systems ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sistemas proprios" ON public.ras_systems FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_ras_updated BEFORE UPDATE ON public.ras_systems FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.experiments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  nome TEXT NOT NULL,
  objetivo TEXT,
  descricao TEXT,
  data_planejada DATE,
  observacoes TEXT,
  status TEXT NOT NULL DEFAULT 'NAO_INICIADO',
  fase TEXT,
  iniciado_em TIMESTAMPTZ,
  encerrado_em TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.experiments TO authenticated;
GRANT ALL ON public.experiments TO service_role;
ALTER TABLE public.experiments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "experimentos proprios" ON public.experiments FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_exp_updated BEFORE UPDATE ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  medido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  classificacao TEXT NOT NULL DEFAULT 'MEDIDO',
  tan_min NUMERIC, tan_max NUMERIC,
  no2 NUMERIC, no3 NUMERIC,
  ph NUMERIC CHECK (ph IS NULL OR (ph >= 0 AND ph <= 14)),
  temperatura NUMERIC, alcalinidade NUMERIC, salinidade NUMERIC,
  oxigenio_dissolvido NUMERIC, orp NUMERIC, tss NUMERIC, turbidez NUMERIC,
  dureza NUMERIC, ca NUMERIC, mg NUMERIC, k NUMERIC, na NUMERIC, cl NUMERIC,
  metodo TEXT, instrumento TEXT, local_coleta TEXT, observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT tan_intervalo_valido CHECK (tan_min IS NULL OR tan_max IS NULL OR tan_min <= tan_max)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.measurements TO authenticated;
GRANT ALL ON public.measurements TO service_role;
ALTER TABLE public.measurements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medicoes proprias" ON public.measurements FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  tipo TEXT NOT NULL,
  ocorrido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  quantidade NUMERIC,
  unidade TEXT,
  descricao TEXT,
  observacoes TEXT,
  dados JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT ALL ON public.events TO service_role;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "eventos proprios" ON public.events FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  nome TEXT NOT NULL,
  origem TEXT, laboratorio TEXT,
  data_chegada DATE,
  estagio TEXT,
  quantidade_recebida INTEGER CHECK (quantidade_recebida IS NULL OR quantidade_recebida >= 0),
  quantidade_estocada INTEGER CHECK (quantidade_estocada IS NULL OR quantidade_estocada >= 0),
  peso_medio_g NUMERIC CHECK (peso_medio_g IS NULL OR peso_medio_g >= 0),
  comprimento_medio_mm NUMERIC CHECK (comprimento_medio_mm IS NULL OR comprimento_medio_mm >= 0),
  salinidade_origem NUMERIC, temperatura_origem NUMERIC,
  povoado BOOLEAN NOT NULL DEFAULT false,
  ativo BOOLEAN NOT NULL DEFAULT false,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.batches TO authenticated;
GRANT ALL ON public.batches TO service_role;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "lotes proprios" ON public.batches FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_batches_updated BEFORE UPDATE ON public.batches FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.mbbr_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  volume_reator_l NUMERIC CHECK (volume_reator_l IS NULL OR volume_reator_l >= 0),
  volume_midia_l NUMERIC CHECK (volume_midia_l IS NULL OR volume_midia_l >= 0),
  tipo_midia TEXT,
  ssa_m2_m3 NUMERIC CHECK (ssa_m2_m3 IS NULL OR ssa_m2_m3 >= 0),
  percentual_enchimento NUMERIC CHECK (percentual_enchimento IS NULL OR (percentual_enchimento >= 0 AND percentual_enchimento <= 100)),
  vazao_l_h NUMERIC CHECK (vazao_l_h IS NULL OR vazao_l_h >= 0),
  aeracao_l_min NUMERIC CHECK (aeracao_l_min IS NULL OR aeracao_l_min >= 0),
  estado TEXT NOT NULL DEFAULT 'NAO_ESTABELECIDO',
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mbbr_configs TO authenticated;
GRANT ALL ON public.mbbr_configs TO service_role;
ALTER TABLE public.mbbr_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mbbr proprio" ON public.mbbr_configs FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_mbbr_updated BEFORE UPDATE ON public.mbbr_configs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.biofilter_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  nome TEXT NOT NULL,
  iniciado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  tan_inicial NUMERIC, no2_inicial NUMERIC, no3_inicial NUMERIC,
  ph NUMERIC CHECK (ph IS NULL OR (ph >= 0 AND ph <= 14)),
  temperatura NUMERIC, salinidade NUMERIC,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.biofilter_tests TO authenticated;
GRANT ALL ON public.biofilter_tests TO service_role;
ALTER TABLE public.biofilter_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "testes proprios" ON public.biofilter_tests FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.biofilter_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  test_id UUID NOT NULL REFERENCES public.biofilter_tests ON DELETE CASCADE,
  lido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  tan NUMERIC, no2 NUMERIC, no3 NUMERIC, ph NUMERIC, temperatura NUMERIC,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.biofilter_readings TO authenticated;
GRANT ALL ON public.biofilter_readings TO service_role;
ALTER TABLE public.biofilter_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "leituras proprias" ON public.biofilter_readings FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.biometry_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  batch_id UUID REFERENCES public.batches ON DELETE SET NULL,
  realizada_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  pesos NUMERIC[] NOT NULL DEFAULT '{}',
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.biometry_records TO authenticated;
GRANT ALL ON public.biometry_records TO service_role;
ALTER TABLE public.biometry_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "biometrias proprias" ON public.biometry_records FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.mortality_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  batch_id UUID REFERENCES public.batches ON DELETE SET NULL,
  ocorrido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  quantidade INTEGER NOT NULL CHECK (quantidade >= 0),
  causa_provavel TEXT,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mortality_records TO authenticated;
GRANT ALL ON public.mortality_records TO service_role;
ALTER TABLE public.mortality_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mortalidade propria" ON public.mortality_records FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.feed_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  fabricante TEXT, produto TEXT NOT NULL,
  proteina_pct NUMERIC, lipidios_pct NUMERIC, umidade_pct NUMERIC,
  granulometria TEXT, preco_kg NUMERIC CHECK (preco_kg IS NULL OR preco_kg >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feed_products TO authenticated;
GRANT ALL ON public.feed_products TO service_role;
ALTER TABLE public.feed_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "racoes proprias" ON public.feed_products FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.feed_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  feed_product_id UUID REFERENCES public.feed_products ON DELETE SET NULL,
  ofertado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  quantidade_g NUMERIC CHECK (quantidade_g IS NULL OR quantidade_g >= 0),
  refeicoes INTEGER CHECK (refeicoes IS NULL OR refeicoes >= 0),
  sobra_estimada_g NUMERIC CHECK (sobra_estimada_g IS NULL OR sobra_estimada_g >= 0),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feed_records TO authenticated;
GRANT ALL ON public.feed_records TO service_role;
ALTER TABLE public.feed_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alimentacao propria" ON public.feed_records FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.mineral_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  nome TEXT NOT NULL,
  forma_quimica TEXT,
  pureza_pct NUMERIC CHECK (pureza_pct IS NULL OR (pureza_pct >= 0 AND pureza_pct <= 100)),
  estoque_kg NUMERIC CHECK (estoque_kg IS NULL OR estoque_kg >= 0),
  preco_kg NUMERIC CHECK (preco_kg IS NULL OR preco_kg >= 0),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mineral_products TO authenticated;
GRANT ALL ON public.mineral_products TO service_role;
ALTER TABLE public.mineral_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "minerais proprios" ON public.mineral_products FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.mineral_additions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  mineral_product_id UUID REFERENCES public.mineral_products ON DELETE SET NULL,
  adicionado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  quantidade_g NUMERIC CHECK (quantidade_g IS NULL OR quantidade_g >= 0),
  etapa TEXT,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mineral_additions TO authenticated;
GRANT ALL ON public.mineral_additions TO service_role;
ALTER TABLE public.mineral_additions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "adicoes proprias" ON public.mineral_additions FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  system_id UUID NOT NULL REFERENCES public.ras_systems ON DELETE CASCADE,
  experiment_id UUID REFERENCES public.experiments ON DELETE SET NULL,
  nivel TEXT NOT NULL DEFAULT 'INFORMATIVO',
  parametro TEXT,
  valor TEXT,
  origem TEXT,
  limite TEXT,
  motivo TEXT,
  acao_verificacao TEXT,
  medido_em TIMESTAMPTZ,
  reconhecido BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.alerts TO authenticated;
GRANT ALL ON public.alerts TO service_role;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alertas proprios" ON public.alerts FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.reference_ranges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  especie TEXT NOT NULL DEFAULT 'Litopenaeus vannamei',
  fase TEXT,
  parametro TEXT NOT NULL,
  minimo NUMERIC, ideal_minimo NUMERIC, ideal_maximo NUMERIC, maximo NUMERIC,
  unidade TEXT,
  fonte TEXT,
  observacao TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reference_ranges TO authenticated;
GRANT ALL ON public.reference_ranges TO service_role;
ALTER TABLE public.reference_ranges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "limites proprios" ON public.reference_ranges FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE TRIGGER trg_ref_updated BEFORE UPDATE ON public.reference_ranges FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX idx_meas_sys_time ON public.measurements (system_id, medido_em DESC);
CREATE INDEX idx_events_sys_time ON public.events (system_id, ocorrido_em DESC);
CREATE INDEX idx_exp_sys ON public.experiments (system_id);
