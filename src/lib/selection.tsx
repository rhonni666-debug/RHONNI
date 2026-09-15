import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import type { Experimento, Sistema } from "./model";

type Ctx={userId:string;sistemas:Sistema[];experimentos:Experimento[];sistema:Sistema|null;experimento:Experimento|null;selecionarSistema:(id:string)=>void;selecionarExperimento:(id:string)=>void;recarregar:()=>void};
const C=createContext<Ctx|null>(null);
export function SelectionProvider({userId,children}:{userId:string;children:ReactNode}){
 const [sid,setSid]=useState<string|null>(null),[eid,setEid]=useState<string|null>(null);
 useEffect(()=>{setSid(localStorage.getItem("ras:sistema"));setEid(localStorage.getItem("ras:experimento"));},[]);
 const sq=useQuery({queryKey:["systems",userId],queryFn:async()=>{const {data,error}=await supabase.from("ras_systems").select("*").order("created_at");if(error)throw error;return (data??[]) as Sistema[];}});
 const sistemas=useMemo(()=>sq.data??[],[sq.data]); const sistema=sistemas.find(s=>s.id===sid)??sistemas[0]??null;
 const eq=useQuery({queryKey:["experiments",sistema?.id],enabled:!!sistema,queryFn:async()=>{const {data,error}=await supabase.from("experiments").select("*").eq("system_id",sistema!.id).order("created_at");if(error)throw error;return (data??[]) as Experimento[];}});
 const experimentos=useMemo(()=>eq.data??[],[eq.data]); const experimento=experimentos.find(e=>e.id===eid)??experimentos[0]??null;
 const recarregar=()=>{void sq.refetch();void eq.refetch();};
 return <C.Provider value={{userId,sistemas,experimentos,sistema,experimento,selecionarSistema:id=>{localStorage.setItem("ras:sistema",id);localStorage.removeItem("ras:experimento");setSid(id);setEid(null);},selecionarExperimento:id=>{localStorage.setItem("ras:experimento",id);setEid(id);},recarregar}}>{children}</C.Provider>;
}
export function useSelection(){const c=useContext(C);if(!c)throw new Error("SelectionProvider ausente");return c;}
