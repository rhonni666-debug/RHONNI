import { QueryClient } from "@tanstack/react-query";
import { createRouter } from "@tanstack/react-router";
import { routeTree } from "./routeTree.gen";

export const getRouter = () => {
  const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 15_000 } } });
  const basepath = import.meta.env.BASE_URL.replace(/\/$/, "") || "/";
  return createRouter({ routeTree, context: { queryClient }, scrollRestoration: true, basepath });
};
