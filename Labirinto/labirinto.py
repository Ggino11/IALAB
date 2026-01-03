import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import tkinter as tk
from tkinter import messagebox, simpledialog
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import os
from PIL import Image

class LabirintoCreator:
    def __init__(self):
        self.size = self.get_grid_size()
        if self.size is None:
            return  # L'utente ha annullato
            
        self.grid = np.zeros((self.size, self.size), dtype=int)
        self.start_pos = None
        self.exit_positions = []
        self.mode = "ostacolo"
        self.mouse_pressed = False
        
        # Crea la finestra principale
        self.root = tk.Tk()
        self.root.title(f"Creatore Labirinto {self.size}x{self.size}")
        self.root.geometry("800x700")
        
        # Crea il frame per la griglia
        self.frame_grid = tk.Frame(self.root)
        self.frame_grid.pack(side=tk.TOP, fill=tk.BOTH, expand=True)
        
        # Crea la figura e l'asse per il labirinto
        self.fig, self.ax = plt.subplots(figsize=(6, 6))
        
        # Inserisci la figura in un canvas tkinter
        self.canvas = FigureCanvasTkAgg(self.fig, master=self.frame_grid)
        self.canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=True)
        
        # Setup iniziale del plot
        self.setup_plot()
        
        # Collega gli eventi del mouse
        self.fig.canvas.mpl_connect('button_press_event', self.on_click_press)
        self.fig.canvas.mpl_connect('button_release_event', self.on_click_release)
        self.fig.canvas.mpl_connect('motion_notify_event', self.on_motion)
        
        # Crea il frame per i pulsanti
        self.frame_buttons = tk.Frame(self.root)
        self.frame_buttons.pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=10)
        
        # Crea i pulsanti
        self.btn_ostacolo = tk.Button(self.frame_buttons, text="Aggiungi Ostacoli", command=lambda: self.set_mode("ostacolo"))
        self.btn_ostacolo.pack(side=tk.LEFT, padx=5)
        
        self.btn_start = tk.Button(self.frame_buttons, text="Imposta Start", command=lambda: self.set_mode("start"))
        self.btn_start.pack(side=tk.LEFT, padx=5)
        
        self.btn_exit = tk.Button(self.frame_buttons, text="Aggiungi Uscita", command=lambda: self.set_mode("exit"))
        self.btn_exit.pack(side=tk.LEFT, padx=5)
        
        self.btn_pulisci = tk.Button(self.frame_buttons, text="Pulisci Cella", command=lambda: self.set_mode("pulisci"))
        self.btn_pulisci.pack(side=tk.LEFT, padx=5)
        
        self.btn_ridimensiona = tk.Button(self.frame_buttons, text="Ridimensiona", command=self.resize_grid)
        self.btn_ridimensiona.pack(side=tk.LEFT, padx=5)
        
        self.btn_genera = tk.Button(self.frame_buttons, text="Genera File Prolog", command=self.generate_prolog_file)
        self.btn_genera.pack(side=tk.RIGHT, padx=5)
        
        self.btn_salva_img = tk.Button(self.frame_buttons, text="Salva Immagine", command=self.save_image)
        self.btn_salva_img.pack(side=tk.RIGHT, padx=5)
        
        self.btn_esci = tk.Button(self.frame_buttons, text="Esci", command=self.root.quit)
        self.btn_esci.pack(side=tk.RIGHT, padx=5)
        
        # Etichetta per lo stato
        self.lbl_status = tk.Label(self.root, text="Modalità: Aggiungi Ostacoli - Clicca o trascina per aggiungere ostacoli")
        self.lbl_status.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Etichetta per le dimensioni
        self.lbl_size = tk.Label(self.root, text=f"Dimensione: {self.size}x{self.size}")
        self.lbl_size.pack(side=tk.BOTTOM, fill=tk.X)
        
        self.root.mainloop()
    
    def get_grid_size(self):
        """Chiede all'utente la dimensione della griglia"""
        root = tk.Tk()
        root.withdraw()
        
        while True:
            size_str = simpledialog.askstring(
                "Dimensione Labirinto", 
                "Inserisci la dimensione del labirinto (max 250):", 
                initialvalue="10"
            )
            
            if size_str is None:
                return None
                
            try:
                size = int(size_str)
                if 1 <= size <= 250:
                    return size
                else:
                    messagebox.showerror("Errore", "La dimensione deve essere tra 1 e 250!")
            except ValueError:
                messagebox.showerror("Errore", "Inserisci un numero valido!")
    
    def setup_plot(self):
        self.ax.clear()
        self.ax.set_xlim(0, self.size)
        self.ax.set_ylim(0, self.size)
        
        # Rimuovi i numeri dagli assi
        self.ax.set_xticks([])
        self.ax.set_yticks([])
        
        # Aggiungi griglia senza numeri
        self.ax.set_xticks(np.arange(0, self.size+1, 1), minor=True)
        self.ax.set_yticks(np.arange(0, self.size+1, 1), minor=True)
        self.ax.grid(which='minor', color='gray', linestyle='-', linewidth=0.5)
        
        self.ax.set_title(f"Labirinto {self.size}x{self.size}")
        
        # Disegna la griglia
        for i in range(self.size):
            for j in range(self.size):
                if self.grid[i, j] == 1:  # Ostacolo
                    self.ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='black'))
                elif self.grid[i, j] == 2:  # Uscita
                    self.ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='green'))
                elif self.grid[i, j] == 3:  # Start
                    self.ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='blue'))
        
        self.canvas.draw()
    
    def on_click_press(self, event):
        """Quando il mouse viene premuto"""
        self.mouse_pressed = True
        self.process_cell(event)
    
    def on_click_release(self, event):
        """Quando il mouse viene rilasciato"""
        self.mouse_pressed = False
    
    def on_motion(self, event):
        """Quando il mouse si muove (trascinamento)"""
        if self.mouse_pressed:
            self.process_cell(event)
    
    def process_cell(self, event):
        """Elabora la cella cliccata"""
        if event.xdata is None or event.ydata is None:
            return
        
        col = int(event.xdata)
        row = self.size - 1 - int(event.ydata)
        
        if 0 <= row < self.size and 0 <= col < self.size:
            if self.mode == "ostacolo":
                self.grid[row, col] = 1
            elif self.mode == "start":
                if self.start_pos:
                    old_row, old_col = self.start_pos
                    if self.grid[old_row, old_col] == 3:
                        self.grid[old_row, old_col] = 0
                self.grid[row, col] = 3
                self.start_pos = (row, col)
            elif self.mode == "exit":
                self.grid[row, col] = 2
                if (row, col) not in self.exit_positions:
                    self.exit_positions.append((row, col))
            elif self.mode == "pulisci":
                if (row, col) == self.start_pos:
                    self.start_pos = None
                elif (row, col) in self.exit_positions:
                    self.exit_positions.remove((row, col))
                self.grid[row, col] = 0
            
            self.setup_plot()
    
    def resize_grid(self):
        """Ridimensiona la griglia"""
        new_size = self.get_grid_size()
        if new_size is None or new_size == self.size:
            return
            
        old_size = self.size
        self.size = new_size
        new_grid = np.zeros((new_size, new_size), dtype=int)
        
        copy_size = min(old_size, new_size)
        new_grid[:copy_size, :copy_size] = self.grid[:copy_size, :copy_size]
        
        self.grid = new_grid
        
        if self.start_pos:
            row, col = self.start_pos
            if row >= new_size or col >= new_size:
                self.start_pos = None
                self.grid[self.grid == 3] = 0
        
        self.exit_positions = [(r, c) for r, c in self.exit_positions if r < new_size and c < new_size]
        for r, c in self.exit_positions:
            self.grid[r, c] = 2
        
        self.root.title(f"Creatore Labirinto {self.size}x{self.size}")
        self.lbl_size.config(text=f"Dimensione: {self.size}x{self.size}")
        self.setup_plot()
    
    def set_mode(self, mode):
        self.mode = mode
        if mode == "ostacolo":
            self.lbl_status.config(text="Modalità: Aggiungi Ostacoli - Clicca o trascina per aggiungere ostacoli")
        elif mode == "start":
            self.lbl_status.config(text="Modalità: Imposta Start - Clicca per impostare il punto di partenza")
        elif mode == "exit":
            self.lbl_status.config(text="Modalità: Aggiungi Uscita - Clicca o trascina per aggiungere uscite")
        elif mode == "pulisci":
            self.lbl_status.config(text="Modalità: Pulisci Cella - Clicca o trascina per pulire celle")
    
    def generate_prolog_file(self):
        if self.start_pos is None:
            messagebox.showerror("Errore", "Devi prima impostare un punto di partenza!")
            return

        if not self.exit_positions:
            messagebox.showerror("Errore", "Devi prima impostare almeno un'uscita!")
            return

        os.makedirs('Labirinto', exist_ok=True)

        with open('Labirinto/labirinto.pl', 'w') as f:
            f.write("/* Dominio del labirinto generato tramite python */\n\n")

            f.write(f"num_righe({self.size}).\n")
            f.write(f"num_colonne({self.size}).\n\n")

            start_y = self.start_pos[1] + 1
            start_x = self.start_pos[0] + 1
            f.write(f"iniziale(pos({start_x},{start_y})).\n\n")

            f.write("% Posizioni finali (uscite)\n")
            for exit_pos in self.exit_positions:
                exit_y = exit_pos[1] + 1
                exit_x = exit_pos[0] + 1
                f.write(f"finale(pos({exit_x},{exit_y})).\n")
            f.write("\n")

            f.write("% Celle occupate (ostacoli)\n")
            for i in range(self.size):
                for j in range(self.size):
                    if self.grid[i, j] == 1:
                        obst_y = j + 1
                        obst_x = i + 1
                        f.write(f"occupata(pos({obst_x},{obst_y})).\n")
        
        messagebox.showinfo("Successo", "File 'Labirinto/labirinto.pl' generato con successo!")
        
        with open('Labirinto/labirinto.pl', 'r') as f:
            content = f.read()
        
        preview = tk.Toplevel(self.root)
        preview.title("Anteprima File Prolog")
        preview.geometry("600x400")
        
        text_widget = tk.Text(preview, wrap=tk.WORD)
        text_widget.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        text_widget.insert(tk.END, content)
        text_widget.config(state=tk.DISABLED)
        
        btn_close = tk.Button(preview, text="Chiudi", command=preview.destroy)
        btn_close.pack(pady=10)
    
    def save_image(self):
        """Salva il labirinto come immagine PNG"""
        if not os.path.exists('Labirinto'):
            os.makedirs('Labirinto')
        
        fig, ax = plt.subplots(figsize=(8, 8))
        ax.set_xlim(0, self.size)
        ax.set_ylim(0, self.size)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_xticks(np.arange(0, self.size+1, 1), minor=True)
        ax.set_yticks(np.arange(0, self.size+1, 1), minor=True)
        ax.grid(which='minor', color='gray', linestyle='-', linewidth=0.5)
        ax.set_title(f"Labirinto {self.size}x{self.size}")
        
        for i in range(self.size):
            for j in range(self.size):
                if self.grid[i, j] == 1:
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='black'))
                elif self.grid[i, j] == 2:
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='green'))
                elif self.grid[i, j] == 3:
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='blue'))
        
        plt.savefig('Labirinto/labirinto.png', dpi=300, bbox_inches='tight')
        plt.close(fig)
        
        messagebox.showinfo("Successo", "Immagine salvata come 'Labirinto/labirinto.png'")

# Esegui l'applicazione
if __name__ == "__main__":
    app = LabirintoCreator()