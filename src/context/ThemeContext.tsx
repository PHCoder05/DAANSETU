'use client'

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

export const ThemeProvider = ({ children }: { children: ReactNode }) => {
  // Check if we're on client-side before accessing localStorage
  const [mounted, setMounted] = useState(false);
  
  // Initial theme is light, will be updated after component mounts
  const [theme, setTheme] = useState<Theme>('light');

  // After mounting, we can safely access localStorage and detect the theme
  useEffect(() => {
    setMounted(true);
    
    try {
      // First check if dark mode is already applied to document
      const isDarkModeActive = document.documentElement.classList.contains('dark');
      
      // Get saved theme from localStorage or use system preference
      const savedTheme = localStorage.getItem('theme') as Theme | null;
      const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      
      console.log('Theme detection:', { 
        savedTheme, 
        systemPrefersDark,
        isDarkModeActive,
        documentClasses: document.documentElement.classList
      });
      
      // Initialize based on actual DOM state first, then stored preference, then system preference
      if (isDarkModeActive) {
        setTheme('dark');
        localStorage.setItem('theme', 'dark');
      } else if (savedTheme) {
        setTheme(savedTheme);
        // Ensure the dark class matches the saved theme
        if (savedTheme === 'dark') {
          document.documentElement.classList.add('dark');
        } else {
          document.documentElement.classList.remove('dark');
        }
      } else if (systemPrefersDark) {
        setTheme('dark');
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme', 'dark');
      }
    } catch (error) {
      console.error('Error initializing theme:', error);
    }
  }, []);

  const toggleTheme = () => {
    try {
      setTheme((prevTheme) => {
        const newTheme = prevTheme === 'light' ? 'dark' : 'light';
        console.log('Toggling theme from', prevTheme, 'to', newTheme);
        
        // Save to localStorage
        localStorage.setItem('theme', newTheme);
        
        // Apply or remove dark class
        if (newTheme === 'dark') {
          document.documentElement.classList.add('dark');
        } else {
          document.documentElement.classList.remove('dark');
        }
        
        return newTheme;
      });
    } catch (error) {
      console.error('Error toggling theme:', error);
    }
  };
  
  // Create value object to avoid unnecessary re-renders
  const contextValue = React.useMemo(() => ({ 
    theme, 
    toggleTheme 
  }), [theme]);
  
  // Provide a noop function during server rendering
  if (!mounted) {
    // Return a minimal context value during SSR
    return (
      <ThemeContext.Provider 
        value={{ 
          theme: 'light', 
          toggleTheme: () => {} 
        }}
      >
        {children}
      </ThemeContext.Provider>
    );
  }

  return (
    <ThemeContext.Provider value={contextValue}>
      {children}
    </ThemeContext.Provider>
  );
}; 