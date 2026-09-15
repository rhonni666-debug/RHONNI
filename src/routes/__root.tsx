import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { HeadContent, Link, Outlet, Scripts, createRootRouteWithContext } from "@tanstack/react-router";
import { Toaster } from "sonner";
import type { ReactNode } from "react";
import appCss from "../styles.css?url";

export const Route=createRootRouteWithContext<{queryClient:QueryClient}>()({
 head:()=>({meta:[{charSet:"utf-8"},{name:"viewport",content:"width=device-width, initial-scale=1"},{title:"RAS Digital Twin"},{name:"description",content:"Monitoramento experimental de Litopenaeus vannamei em RAS."}],links:[{rel:"stylesheet",href:appCss},{rel:"preconnect",href:"https://fonts.googleapis.com"},{rel:"stylesheet",href:"https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap"}]}),
 shellComponent:({children}:{children:ReactNode})=><html lang="pt-BR"><head><HeadContent/></head><body>{children}<Scripts/></body></html>,
 component:()=>{const {queryClient}=Route.useRouteContext();return <QueryClientProvider client={queryClient}><Outlet/><Toaster richColors position="top-right"/></QueryClientProvider>},
 notFoundComponent:()=> <div className="min-h-screen grid place-items-center p-6"><div className="card text-center"><h1 className="text-2xl font-bold">Página não encontrada</h1><Link className="btn mt-4" to="/">Voltar ao início</Link></div></div>
});
