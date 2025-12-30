import { create } from "zustand";

/**
 * Simple auth store for managing user authentication state
 * This is a minimal implementation that can be extended as needed
 */
interface User {
    id: string;
    username: string;
    token: string;
}

interface AuthState {
    user: User | null;
    setUser: (user: User | null) => void;
    login: (user: User, token: string) => void;
    logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,

  setUser: (user) => set({ user }),

  login: (user, token) => set({ user: { ...user, token } }),
  logout: () => set({ user: null }),
}));
