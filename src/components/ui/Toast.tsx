'use client';

import React from 'react';
import { Toaster, toast as hotToast } from 'react-hot-toast';
import { AlertCircle, CheckCircle, Info, X, AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

// Toast types with corresponding styling
export type ToastType = 'success' | 'error' | 'info' | 'warning';

// Custom Toast Component
const CustomToast = ({ 
  visible, 
  message, 
  type = 'info',
  onDismiss 
}: { 
  visible: boolean; 
  message: string; 
  type?: ToastType; 
  onDismiss: () => void;
}) => {
  const Icon = React.useMemo(() => {
    switch (type) {
      case 'success':
        return CheckCircle;
      case 'error':
        return AlertCircle;
      case 'warning':
        return AlertTriangle;
      case 'info':
      default:
        return Info;
    }
  }, [type]);

  // Base and type-specific styles
  const baseStyles = 'max-w-md w-full bg-white dark:bg-zinc-800 shadow-lg rounded-lg pointer-events-auto flex ring-1 ring-black ring-opacity-5';
  const typeStyles = {
    success: 'ring-green-500/20 dark:ring-green-500/40',
    error: 'ring-red-500/20 dark:ring-red-500/40',
    info: 'ring-blue-500/20 dark:ring-blue-500/40',
    warning: 'ring-amber-500/20 dark:ring-amber-500/40',
  };

  // Icon color based on type
  const iconColor = {
    success: 'text-green-500 dark:text-green-400',
    error: 'text-red-500 dark:text-red-400',
    info: 'text-blue-500 dark:text-blue-400',
    warning: 'text-amber-500 dark:text-amber-400',
  };

  return (
    <div
      className={cn(
        baseStyles,
        typeStyles[type],
        'opacity-0 transition-all duration-300 ease-out transform scale-95 translate-y-2',
        visible && 'opacity-100 scale-100 translate-y-0'
      )}
    >
      <div className="flex-1 p-4 w-0">
        <div className="flex items-start">
          <div className="flex-shrink-0">
            <Icon className={cn("h-5 w-5", iconColor[type])} />
          </div>
          <div className="ml-3 flex-1">
            <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
              {message}
            </p>
          </div>
        </div>
      </div>
      <div className="flex">
        <button
          onClick={onDismiss}
          className="w-full p-4 flex justify-center text-sm font-medium text-gray-400 hover:text-gray-500 dark:hover:text-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-300 dark:focus:ring-gray-600"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
    </div>
  );
};

// Toast Provider that wraps react-hot-toast
export const ToastProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <>
      {children}
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 5000,
          style: {
            background: 'transparent',
            boxShadow: 'none',
            padding: 0,
            margin: 0,
          },
        }}
      />
    </>
  );
};

// Enhanced toast notification functions
export const toast = {
  // Success toast
  success: (message: string, options = {}) => {
    return hotToast.custom(
      (t) => (
        <CustomToast
          visible={t.visible}
          message={message}
          type="success"
          onDismiss={() => hotToast.dismiss(t.id)}
        />
      ),
      {
        duration: 4000,
        ...options
      }
    );
  },

  // Error toast
  error: (message: string, options = {}) => {
    return hotToast.custom(
      (t) => (
        <CustomToast
          visible={t.visible}
          message={message}
          type="error"
          onDismiss={() => hotToast.dismiss(t.id)}
        />
      ),
      {
        duration: 5000,
        ...options
      }
    );
  },

  // Info toast
  info: (message: string, options = {}) => {
    return hotToast.custom(
      (t) => (
        <CustomToast
          visible={t.visible}
          message={message}
          type="info"
          onDismiss={() => hotToast.dismiss(t.id)}
        />
      ),
      {
        duration: 4000,
        ...options
      }
    );
  },

  // Warning toast
  warning: (message: string, options = {}) => {
    return hotToast.custom(
      (t) => (
        <CustomToast
          visible={t.visible}
          message={message}
          type="warning"
          onDismiss={() => hotToast.dismiss(t.id)}
        />
      ),
      {
        duration: 4500,
        ...options
      }
    );
  },

  // Dismiss a specific toast
  dismiss: hotToast.dismiss,

  // Dismiss all toasts
  dismissAll: hotToast.dismiss,
}; 