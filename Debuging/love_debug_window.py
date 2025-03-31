import tkinter as tk
from tkinter import ttk, scrolledtext
import socket
import threading
import json
import time
from datetime import datetime
from tkinter.font import Font

class ModernDebugConsole:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("LÖVE Debug Console")
        self.root.geometry("1024x768")
        
        self.colors = {
            'bg': '#1a1a1a',
            'text': '#e0e0e0',
            'accent': '#007acc',
            'success': '#4ec9b0',
            'warning': '#dcdcaa',
            'error': '#f44747',
            'timestamp': '#569cd6',
            'toolbar': '#252526'
        }
        
        self.root.configure(bg=self.colors['bg'])
        
        # Configure styles
        self.style = ttk.Style()
        self.style.configure('Modern.TFrame', background=self.colors['bg'])
        self.style.configure('Toolbar.TFrame', background=self.colors['toolbar'])
        self.style.configure('Modern.TButton',
                           background=self.colors['accent'],
                           foreground=self.colors['text'],
                           padding=5)
        self.style.configure('Modern.TCheckbutton',
                           background=self.colors['toolbar'],
                           foreground=self.colors['text'])
        self.style.configure('Modern.TLabel',
                           background=self.colors['toolbar'],
                           foreground=self.colors['text'])
        
        self.setup_ui()
        self.setup_network()
        
    def setup_ui(self):
        self.main_frame = ttk.Frame(self.root, style='Modern.TFrame')
        self.main_frame.pack(expand=True, fill='both', padx=2, pady=2)
        self.create_toolbar()
        self.create_console()
        self.create_status_bar()
        
    def create_toolbar(self):
        toolbar = ttk.Frame(self.main_frame, style='Toolbar.TFrame')
        toolbar.pack(fill='x', pady=1)
        button_font = Font(family='Segoe UI', size=9)
        self.clear_btn = ttk.Button(toolbar,
                                  text="⌧ Clear",
                                  command=self.clear_console,
                                  style='Modern.TButton')
        self.clear_btn.pack(side='left', padx=5, pady=5)
        
        self.autoscroll_var = tk.BooleanVar(value=True)
        self.autoscroll_cb = ttk.Checkbutton(
            toolbar,
            text="📜 Auto-scroll",
            variable=self.autoscroll_var,
            style='Modern.TCheckbutton')
        self.autoscroll_cb.pack(side='left', padx=10)
        search_frame = ttk.Frame(toolbar, style='Toolbar.TFrame')
        search_frame.pack(side='left', fill='x', expand=True, padx=10)
        
        ttk.Label(search_frame,
                 text="🔍",
                 style='Modern.TLabel').pack(side='left', padx=2)
        
        self.filter_var = tk.StringVar()
        self.filter_var.trace('w', self.apply_filter)
        self.filter_entry = ttk.Entry(
            search_frame,
            textvariable=self.filter_var,
            font=('Consolas', 10))
        self.filter_entry.pack(side='left', fill='x', expand=True)
        self.counter_label = ttk.Label(
            toolbar,
            text="Messages: 0",
            style='Modern.TLabel')
        self.counter_label.pack(side='right', padx=10)
        
    def create_console(self):
        console_frame = ttk.Frame(self.main_frame, style='Modern.TFrame')
        console_frame.pack(expand=True, fill='both', padx=2, pady=2)
        
        self.text_area = scrolledtext.ScrolledText(
            console_frame,
            wrap=tk.WORD,
            bg=self.colors['bg'],
            fg=self.colors['text'],
            font=('JetBrains Mono', 10),
            insertbackground=self.colors['text'],
            pady=5,
            padx=5
        )
        self.text_area.pack(expand=True, fill='both')
        
        # Configure text tags with modern colors
        self.text_area.tag_configure('timestamp',
                                   foreground=self.colors['timestamp'])
        self.text_area.tag_configure('message',
                                   foreground=self.colors['text'])
        self.text_area.tag_configure('error',
                                   foreground=self.colors['error'])
        self.text_area.tag_configure('warning',
                                   foreground=self.colors['warning'])
        self.text_area.tag_configure('success',
                                   foreground=self.colors['success'])
    
    def create_status_bar(self):
        status_bar = ttk.Frame(self.main_frame, style='Toolbar.TFrame')
        status_bar.pack(fill='x', pady=1)
        
        self.status_label = ttk.Label(
            status_bar,
            text="Ready",
            style='Modern.TLabel')
        self.status_label.pack(side='left', padx=5)
        
    def setup_network(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(('localhost', 12345))
        
        self.msg_count = 0
        
        self.listen_thread = threading.Thread(target=self.listen_for_messages)
        self.listen_thread.daemon = True
        self.listen_thread.start()
    
    def add_message(self, message):
        timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
        
        tag = 'message'
        if 'error' in message.lower():
            tag = 'error'
            self.status_label.configure(text="Error received")
        elif 'warning' in message.lower():
            tag = 'warning'
            self.status_label.configure(text="Warning received")
        elif 'success' in message.lower() or 'initialized' in message.lower():
            tag = 'success'
            self.status_label.configure(text="Success")
            
        if self.filter_var.get().lower() not in message.lower():
            return
            
        self.text_area.insert(tk.END, f"[{timestamp}] ", 'timestamp')
        self.text_area.insert(tk.END, f"{message}\n", tag)
        
        if self.autoscroll_var.get():
            self.text_area.see(tk.END)
            
        self.msg_count += 1
        self.counter_label.configure(text=f"📊 Messages: {self.msg_count}")
    
    def clear_console(self):
        self.text_area.delete(1.0, tk.END)
        self.msg_count = 0
        self.counter_label.configure(text="📊 Messages: 0")
        self.status_label.configure(text="Console cleared")
    
    def apply_filter(self, *args):
        current_text = self.text_area.get(1.0, tk.END)
        self.text_area.delete(1.0, tk.END)
        
        filtered_count = 0
        for line in current_text.splitlines():
            if self.filter_var.get().lower() in line.lower():
                self.text_area.insert(tk.END, line + "\n")
                filtered_count += 1
        
        self.status_label.configure(text=f"Filtered: {filtered_count} messages")
    
    def listen_for_messages(self):
        while True:
            try:
                data, addr = self.sock.recvfrom(65535)
                message = data.decode('utf-8')
                self.root.after(0, self.add_message, message)
            except Exception as e:
                self.status_label.configure(text=f"Network error: {str(e)}")
                time.sleep(0.1)
    
    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    console = ModernDebugConsole()
    console.run()