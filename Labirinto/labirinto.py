import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import tkinter as tk
from tkinter import messagebox, simpledialog
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import os
from PIL import Image

class LabirintoCreator:
    def __init__(self, size=10):
        self.size = size
        self.grid = np.zeros((size, size), dtype=int)  # 0 = libero, 1 = ostacolo, 2 = uscita, 3 = start
        self.start_pos = None
        self.exit_positions = []  # Lista per multiple uscite
        self.mode = "ostacolo"  # Modalità predefinita: aggiungi ostacoli
        
        # Crea la finestra principale
        self.root = tk.Tk()
        self.root.title("Creatore Labirinto")
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
        self.fig.canvas.mpl_connect('button_press_event', self.on_click)
        
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
        
        self.btn_genera = tk.Button(self.frame_buttons, text="Genera File Prolog", command=self.generate_prolog_file)
        self.btn_genera.pack(side=tk.RIGHT, padx=5)
        
        self.btn_salva_img = tk.Button(self.frame_buttons, text="Salva Immagine", command=self.save_image)
        self.btn_salva_img.pack(side=tk.RIGHT, padx=5)
        
        self.btn_esci = tk.Button(self.frame_buttons, text="Esci", command=self.root.quit)
        self.btn_esci.pack(side=tk.RIGHT, padx=5)
        
        # Etichetta per lo stato
        self.lbl_status = tk.Label(self.root, text="Modalità: Aggiungi Ostacoli - Clicca sulla griglia per aggiungere ostacoli")
        self.lbl_status.pack(side=tk.BOTTOM, fill=tk.X)
        
        self.root.mainloop()
    
    def set_mode(self, mode):
        self.mode = mode
        if mode == "ostacolo":
            self.lbl_status.config(text="Modalità: Aggiungi Ostacoli - Clicca sulla griglia per aggiungere ostacoli")
        elif mode == "start":
            self.lbl_status.config(text="Modalità: Imposta Start - Clicca sulla griglia per impostare il punto di partenza")
        elif mode == "exit":
            self.lbl_status.config(text="Modalità: Aggiungi Uscita - Clicca sulla griglia per aggiungere un'uscita")
        elif mode == "pulisci":
            self.lbl_status.config(text="Modalità: Pulisci Cella - Clicca sulla griglia per pulire la cella")
    
    def setup_plot(self):
        self.ax.clear()
        self.ax.set_xlim(0, self.size)
        self.ax.set_ylim(0, self.size)
        self.ax.set_xticks(np.arange(0, self.size+1, 1))
        self.ax.set_yticks(np.arange(0, self.size+1, 1))
        self.ax.grid(True)
        self.ax.set_title("Labirinto - Seleziona le celle")
        
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
    
    def on_click(self, event):
        if event.xdata is None or event.ydata is None:
            return
        
        col = int(event.xdata)
        row = self.size - 1 - int(event.ydata)
        
        if 0 <= row < self.size and 0 <= col < self.size:
            if self.mode == "ostacolo":
                self.grid[row, col] = 1
            elif self.mode == "start":
                # Rimuovi il vecchio start se esiste
                if self.start_pos:
                    old_row, old_col = self.start_pos
                    if self.grid[old_row, old_col] == 3:  # Se era start
                        self.grid[old_row, old_col] = 0
                self.grid[row, col] = 3
                self.start_pos = (row, col)
            elif self.mode == "exit":
                # Aggiungi una nuova uscita
                self.grid[row, col] = 2
                self.exit_positions.append((row, col))
            elif self.mode == "pulisci":
                # Pulisci la cella
                if (row, col) == self.start_pos:
                    self.start_pos = None
                elif (row, col) in self.exit_positions:
                    self.exit_positions.remove((row, col))
                self.grid[row, col] = 0
            
            self.setup_plot()
    
    def generate_prolog_file(self):
        if self.start_pos is None:
            messagebox.showerror("Errore", "Devi prima impostare un punto di partenza!")
            return
        
        if not self.exit_positions:
            messagebox.showerror("Errore", "Devi prima impostare almeno un'uscita!")
            return
        
        # Crea la cartella se non esiste
        os.makedirs('Labirinto', exist_ok=True)
        
        # Genera il file di dominio Prolog
        with open('Labirinto/labirinto.pl', 'w') as f:
            f.write("/* Dominio del labirinto generato tramite python */\n\n")
            
            # Definisci il numero di righe e colonne
            f.write(f"num_righe({self.size}).\n")
            f.write(f"num_colonne({self.size}).\n\n")
            
            # Definisci la posizione iniziale (aggiusta le coordinate per la numerazione 1-based)
            start_x = self.start_pos[1] + 1
            start_y = self.start_pos[0] + 1
            f.write(f"iniziale(pos({start_x},{start_y})).\n\n")
            
            # Definisci le posizioni finali (uscite)
            f.write("% Posizioni finali (uscite)\n")
            for exit_pos in self.exit_positions:
                exit_x = exit_pos[1] + 1
                exit_y = exit_pos[0] + 1
                f.write(f"finale(pos({exit_x},{exit_y})).\n")
            f.write("\n")
            
            # Definisci le celle occupate (ostacoli)
            f.write("% Celle occupate (ostacoli)\n")
            for i in range(self.size):
                for j in range(self.size):
                    if self.grid[i, j] == 1:  # Ostacolo
                        # Converti a coordinate 1-based
                        obst_x = j + 1
                        obst_y = i + 1
                        f.write(f"occupata(pos({obst_x},{obst_y})).\n")
        
        messagebox.showinfo("Successo", "File 'Labirinto/labirinto.pl' generato con successo!")
        
        # Mostra anteprima del file
        with open('Labirinto/labirinto.pl', 'r') as f:
            content = f.read()
        
        # Crea una finestra con l'anteprima
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
        
        # Crea una figura separata per il salvataggio
        fig, ax = plt.subplots(figsize=(8, 8))
        ax.set_xlim(0, self.size)
        ax.set_ylim(0, self.size)
        ax.set_xticks(np.arange(0, self.size+1, 1))
        ax.set_yticks(np.arange(0, self.size+1, 1))
        ax.grid(True)
        ax.set_title("Labirinto")
        
        # Disegna la griglia
        for i in range(self.size):
            for j in range(self.size):
                if self.grid[i, j] == 1:  # Ostacolo
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='black'))
                elif self.grid[i, j] == 2:  # Uscita
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='green'))
                elif self.grid[i, j] == 3:  # Start
                    ax.add_patch(Rectangle((j, self.size-1-i), 1, 1, facecolor='blue'))
        
        # Salva l'immagine
        plt.savefig('Labirinto/labirinto.png', dpi=300, bbox_inches='tight')
        plt.close(fig)
        
        messagebox.showinfo("Successo", "Immagine salvata come 'Labirinto/labirinto.png'")

# Esegui l'applicazione
if __name__ == "__main__":
    app = LabirintoCreator()