"use client";

import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";
import { cn } from "@/lib/utils";

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    const root = document.documentElement;
    const stored = localStorage.getItem("theme");
    if (stored === "light") {
      requestAnimationFrame(() => {
        setIsDark(false);
      });
      root.classList.remove("dark");
    } else {
      requestAnimationFrame(() => {
        setIsDark(true);
      });
      root.classList.add("dark");
    }
  }, []);

  const toggle = () => {
    const root = document.documentElement;
    if (isDark) {
      setIsDark(false);
      root.classList.remove("dark");
      localStorage.setItem("theme", "light");
    } else {
      setIsDark(true);
      root.classList.add("dark");
      localStorage.setItem("theme", "dark");
    }
  };

  return (
    <button
      onClick={toggle}
      className={cn(
        "rounded-lg p-2 text-zinc-400 transition-all duration-200",
        "hover:bg-white/5 hover:text-white"
      )}
      aria-label="Toggle theme"
    >
      {isDark ? (
        <Sun className="h-4 w-4" />
      ) : (
        <Moon className="h-4 w-4" />
      )}
    </button>
  );
}