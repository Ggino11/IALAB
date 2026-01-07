"""
Visualizzatore Avanzato Battaglia Navale CLIPS
Distinzione rigorosa: FIRE / GUESS / DEDUZIONI / INIT
"""

import tkinter as tk
from tkinter import ttk, scrolledtext
import re
import subprocess
import time

class BattleshipVisualizerAdvanced:
    def __init__(self, root):
        self.root = root
        self.root.title("Battaglia Navale - Visualizzatore Avanzato")
        self.root.geometry("1400x850")
        
        # Griglia
        self.grid_size = 10
        self.cell_size = 50
        
        # Colori PRECISI secondo specifiche
        self.colors = {
            # FIRE
            'fire_water': '#3498db',      # BLU per acqua osservata
            'fire_ship': '#e74c3c',       # ROSSO per nave osservata
            
            # GUESS
            'guess_active': '#ff8c42',    # ARANCIONE per guess attivo
            'guess_correct': '#2ecc71',   # VERDE per guess corretto
            
            # DEDOTTO (no fire, no guess)
            'deduced_water': '#87ceeb',   # BLU CHIARO per acqua dedotta
            'deduced_ship': '#a8e6cf',    # VERDE CHIARO per nave dedotta
            
            # INIT
            'init_water': '#1f618d',      # DARK BLUE per init water
            'init_ship': '#1e8449',       # DARK GREEN per init ship
            'init': '#ffd700',            # Fallback
            
            # MISSED
            'missed_ship': '#c0392b',     # ROSSO SCURO per navi non trovate
            
            # Default
            'unknown': '#ecf0f1'          # GRIGIO per sconosciuto
        }
        
        # State tracking
        self.agent_cells = {}
        self.real_cells = {}
        self.cell_states = {}  # (x,y) -> {'type': 'fire'/'guess'/'deduced'/'init', 'content': ...}
        self.fired_hits = set()
        self.fired_misses = set()
        
        # Dati
        self.k_per_row = {}
        self.k_per_col = {}
        self.real_map = {}
        
        # Stats
        self.step = 0
        self.score = 0
        self.fires_used = 0
        self.guesses_used = 0
        
        self.setup_ui()
        
    def setup_ui(self):
        # Center the main container in the root window
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        
        self.main_frame = ttk.Frame(self.root, padding="10")
        self.main_frame.grid(row=0, column=0)  # No sticky means it stays centered
        
        # Configure weights for the main container if we wanted stretching, 
        # but for centering fixed size content, default grid behavior works well.
        
        # Top panel - Info
        info_frame = ttk.Frame(self.main_frame, padding="10")
        info_frame.grid(row=0, column=0, columnspan=3, sticky=(tk.W, tk.E))
        
        self.step_label = ttk.Label(info_frame, text="Step: 0", font=('Arial', 14, 'bold'))
        self.step_label.pack(side=tk.LEFT, padx=20)
        
        self.score_label = ttk.Label(info_frame, text="Score: 0", font=('Arial', 14, 'bold'))
        self.score_label.pack(side=tk.LEFT, padx=20)
        
        self.fires_label = ttk.Label(info_frame, text="Fires: 0/5", font=('Arial', 12))
        self.fires_label.pack(side=tk.LEFT, padx=20)
        
        self.guesses_label = ttk.Label(info_frame, text="Guesses: 0/20", font=('Arial', 12))
        self.guesses_label.pack(side=tk.LEFT, padx=20)
        
        # Main content frame
        content_frame = ttk.Frame(self.main_frame, padding="10")
        content_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # LEFT GRID - Agent Knowledge
        left_frame = ttk.LabelFrame(content_frame, text="📊 Conoscenza Agente", padding="10")
        left_frame.grid(row=0, column=0, padx=10, sticky=(tk.N))
        
        self.agent_canvas = tk.Canvas(left_frame, width=self.grid_size*self.cell_size+70,
                                      height=self.grid_size*self.cell_size+70, bg='white')
        self.agent_canvas.pack()
        
        # RIGHT GRID - Real Map
        right_frame = ttk.LabelFrame(content_frame, text="🗺️ Mappa Reale", padding="10")
        right_frame.grid(row=0, column=1, padx=10, sticky=(tk.N))
        
        self.real_canvas = tk.Canvas(right_frame, width=self.grid_size*self.cell_size+70,
                                     height=self.grid_size*self.cell_size+70, bg='white')
        self.real_canvas.pack()
        
        # LOGS PANEL
        logs_frame = ttk.LabelFrame(content_frame, text="📝 Log Azioni", padding="10")
        logs_frame.grid(row=0, column=2, padx=10, sticky=(tk.N, tk.S))
        
        # Log FIRE
        ttk.Label(logs_frame, text="🔥 FIRE", font=('Arial', 10, 'bold')).pack(anchor=tk.W)
        self.fire_log = scrolledtext.ScrolledText(logs_frame, width=30, height=8, font=('Courier', 8))
        self.fire_log.pack(fill=tk.BOTH, pady=(0, 10))
        
        # Log GUESS
        ttk.Label(logs_frame, text="🎯 GUESS", font=('Arial', 10, 'bold')).pack(anchor=tk.W)
        self.guess_log = scrolledtext.ScrolledText(logs_frame, width=30, height=8, font=('Courier', 8))
        self.guess_log.pack(fill=tk.BOTH, pady=(0, 10))
        
        # Log DEDUZIONI
        ttk.Label(logs_frame, text="🧠 DEDUZIONI", font=('Arial', 10, 'bold')).pack(anchor=tk.W)
        self.deduce_log = scrolledtext.ScrolledText(logs_frame, width=30, height=8, font=('Courier', 8))
        self.deduce_log.pack(fill=tk.BOTH)
        
        # Legend
        legend_frame = ttk.LabelFrame(content_frame, text="Legenda", padding="5")
        legend_frame.grid(row=1, column=0, columnspan=3, pady=10, sticky=(tk.W, tk.E))
        
        legends = [
            ("F (blu)", self.colors['fire_water'], "Fire → acqua"),
            ("F (rosso)", self.colors['fire_ship'], "Fire → nave"),
            ("X (arancione)", self.colors['guess_active'], "Guess attivo"),
            ("✓ (verde)", self.colors['guess_correct'], "Guess corretto"),
            ("~ (blu chiaro)", self.colors['deduced_water'], "Acqua dedotta"),
            ("INIT (blu)", self.colors['init_water'], "Init Acqua"),
            ("INIT (verde)", self.colors['init_ship'], "Init Nave"),
            ("? (rosso)", self.colors['missed_ship'], "Nave non trovata"),
        ]
        
        for idx, (label, color, desc) in enumerate(legends):
            row_idx = idx // 4
            col_idx = idx % 4
            frame = tk.Frame(legend_frame, width=15, height=15, bg=color, relief=tk.RAISED, borderwidth=1)
            frame.grid(row=row_idx, column=col_idx*3, padx=2, pady=2)
            ttk.Label(legend_frame, text=label).grid(row=row_idx, column=col_idx*3+1, padx=(2, 5))
            ttk.Label(legend_frame, text=desc, foreground='gray').grid(row=row_idx, column=col_idx*3+2, padx=(0, 15))
        
        # Controls
        control_frame = ttk.Frame(self.main_frame, padding="10")
        control_frame.grid(row=2, column=0, columnspan=3)
        
        # Map Selector
        ttk.Label(control_frame, text="Mappa:").pack(side=tk.LEFT, padx=5)
        self.map_var = tk.StringVar()
        self.map_combo = ttk.Combobox(control_frame, textvariable=self.map_var, state="readonly", width=20)
        self.map_combo.pack(side=tk.LEFT, padx=5)
        
        # Load available maps
        self.load_maps_list()
        
        # Agent Selector
        ttk.Label(control_frame, text="Agente:").pack(side=tk.LEFT, padx=5)
        self.agent_var = tk.StringVar(value="Agent_Strategic.clp")
        self.agent_combo = ttk.Combobox(control_frame, textvariable=self.agent_var, state="readonly", width=20)
        self.agent_combo['values'] = ["Agent_Simple.clp", "Agent_Strategic.clp"]
        self.agent_combo.pack(side=tk.LEFT, padx=5)
        
        ttk.Button(control_frame, text="▶ RUN", command=self.run_selected_agent).pack(side=tk.LEFT, padx=10)
        ttk.Button(control_frame, text="⏹ Reset", command=self.reset).pack(side=tk.LEFT, padx=5)
        
        # Draw grids
        self.draw_grid(self.agent_canvas, self.agent_cells)
        self.draw_grid(self.real_canvas, self.real_cells)
        
        # Load initial map if available
        if self.map_combo['values']:
            self.map_combo.current(0)
            self.load_real_map(self.map_var.get())

    def load_maps_list(self):
        import glob
        import os
        work_dir = os.path.dirname(os.path.abspath(__file__))
        maps = glob.glob(os.path.join(work_dir, "mapEnvironment*.clp"))
        map_names = [os.path.basename(m) for m in maps]
        self.map_combo['values'] = map_names
        
        # Bind selection change
        self.map_combo.bind("<<ComboboxSelected>>", self.on_map_change)

    def on_map_change(self, event):
        self.reset()
        self.load_real_map(self.map_var.get())

    def draw_grid(self, canvas, cells_dict):
        canvas.delete("all")
        
        # Headers columns
        for col in range(self.grid_size):
            x = 50 + col * self.cell_size + self.cell_size // 2
            k_val = self.k_per_col.get(col, '')
            text = f"{col}\n({k_val})" if k_val != '' else str(col)
            canvas.create_text(x, 20, text=text, font=('Arial', 8, 'bold'))
        
        # Headers rows and cells
        for row in range(self.grid_size):
            y = 50 + row * self.cell_size
            k_val = self.k_per_row.get(row, '')
            text = f"{row} ({k_val})" if k_val != '' else str(row)
            canvas.create_text(25, y + self.cell_size // 2, text=text, font=('Arial', 8, 'bold'))
            
            for col in range(self.grid_size):
                x = 50 + col * self.cell_size
                
                cell_id = canvas.create_rectangle(
                    x, y, x + self.cell_size, y + self.cell_size,
                    fill=self.colors['unknown'], outline='#34495e', width=1
                )
                
                text_id = canvas.create_text(
                    x + self.cell_size // 2, y + self.cell_size // 2,
                    text='?', font=('Arial', 14, 'bold')
                )
                
                cells_dict[(row, col)] = {'rect': cell_id, 'text': text_id}
    
    def update_cell(self, canvas, cells_dict, row, col, cell_type, content=''):
        """
        cell_type: 'fire_water'/'fire_ship'/'guess_active'/'guess_correct'/'deduced_water'/'init'/'missed_ship'
        """
        if (row, col) not in cells_dict:
            return
        
        cell = cells_dict[(row, col)]
        color = self.colors.get(cell_type, self.colors['unknown'])
        
        # Specific colors for INIT
        if cell_type == 'init':
            if content == 'water':
                color = self.colors['init_water']
            else:
                color = self.colors['init_ship']
        
        # Determine text
        text_map = {
            'fire_water': 'F',
            'fire_ship': 'F',
            'guess_active': 'X',
            'guess_correct': '✓',
            'deduced_water': '~',
            'deduced_ship': '■',
            'init': '[I]',
            'missed_ship': '?',  # Requested user feature: Red but with '?'
            'unknown': '?'
        }
        text = text_map.get(cell_type, '?')
        # Preserve content for INIT if available
        if cell_type == 'init' and content:
             pass 

        # Custom Borders
        border_color = '#34495e'  # Default default greyish
        border_width = 1
        
        # Priority: INIT > FIRE HIT > FIRE MISS
        if cell_type == 'init':
            border_color = '#8e44ad'  # PURPLE for INIT
            border_width = 3
        elif (row, col) in getattr(self, 'fired_hits', set()):
            border_color = '#e74c3c'  # RED for FIRE HIT (persistent)
            border_width = 4
        elif (row, col) in getattr(self, 'fired_misses', set()) or 'fire' in cell_type:
            border_color = '#000000'  # BLACK for FIRE MISS
            border_width = 3

        canvas.itemconfig(cell['rect'], fill=color, outline=border_color, width=border_width)
        canvas.itemconfig(cell['text'], text=text)
        
        # Store state
        self.cell_states[(row, col)] = {'type': cell_type, 'content': content}
        self.root.update()
    
    def reveal_missed_ships(self):
        """Reveal ships that were not found by the agent"""
        self.log_deduce("🏁 GIOCO FINITO - Rivelo navi mancanti...")
        count = 0
        for (x, y), content in self.real_map.items():
            if content == 'boat':
                # Check if agent knows it
                if (x, y) not in self.cell_states or \
                   self.cell_states[(x, y)]['type'] in ['unknown', 'deduced_water']: # Should not be deduced_water if it's a boat unless error
                    
                    # Also skip if it was a guess match (which is guess_correct) or init
                    current_type = self.cell_states.get((x,y), {}).get('type', 'unknown')
                    if current_type in ['guess_correct', 'fire_ship', 'init']:
                        continue
                        
                    self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'missed_ship')
                    count += 1
                    time.sleep(0.1)
        
        if count > 0:
            self.log_deduce(f"⚠️ {count} navi non trovate (Rosso)")
        else:
            self.log_deduce("🏆 TUTTE le navi trovate!")

    def load_real_map(self, map_file):
        import os
        work_dir = os.path.dirname(os.path.abspath(__file__))
        map_path = os.path.join(work_dir, map_file)
        
        # Clear previous map data
        self.k_per_row = {}
        self.k_per_col = {}
        self.real_map = {}
        
        if not os.path.exists(map_path):
            return
        
        with open(map_path, 'r') as f:
            content = f.read()
            
            # Parse k values
            for match in re.finditer(r'\(k-per-row \(row (\d+)\) \(num (\d+)\)\)', content):
                self.k_per_row[int(match.group(1))] = int(match.group(2))
            
            for match in re.finditer(r'\(k-per-col \(col (\d+)\) \(num (\d+)\)\)', content):
                self.k_per_col[int(match.group(1))] = int(match.group(2))
            
            # Parse real cells
            for match in re.finditer(r'\(cell \(x (\d+)\) \(y (\d+)\) \(content (\w+)\)', content):
                x, y = int(match.group(1)), int(match.group(2))
                cell_content = match.group(3)
                self.real_map[(x, y)] = cell_content
        
        # Redraw with new k values (which clears canvas)
        self.draw_grid(self.agent_canvas, self.agent_cells)
        self.draw_grid(self.real_canvas, self.real_cells)
        
        # Show real map content
        for (x, y), cell_content in self.real_map.items():
            if cell_content == 'water':
                if (x,y) in self.real_cells:
                    cell = self.real_cells[(x, y)]
                    self.real_canvas.itemconfig(cell['rect'], fill=self.colors['fire_water'])
                    self.real_canvas.itemconfig(cell['text'], text='~')
            elif cell_content == 'boat':
                if (x,y) in self.real_cells:
                    cell = self.real_cells[(x, y)]
                    self.real_canvas.itemconfig(cell['rect'], fill=self.colors['fire_ship'])
                    self.real_canvas.itemconfig(cell['text'], text='■')
                    
    def load_init_cells(self, map_file):
        """Load and display initial k-cell knowledge"""
        import os
        work_dir = os.path.dirname(os.path.abspath(__file__))
        map_path = os.path.join(work_dir, map_file)
        
        if not os.path.exists(map_path):
            return
        
        with open(map_path, 'r') as f:
            content = f.read()
            
            # Parse k-cell (initial knowledge)
            for match in re.finditer(r'\(k-cell \(x (\d+)\) \(y (\d+)\) \(content (\w+)\)\)', content):
                x, y = int(match.group(1)), int(match.group(2))
                cell_content = match.group(3)
                
                # Show INIT cells
                self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'init', cell_content)
                self.update_cell(self.real_canvas, self.real_cells, x, y, 'init', cell_content)
                # Avoid logging here if called from inside run_agent to avoid duplicates or clear log first
                # But we call reset() in run_agent so it's fine.
                self.log_deduce(f"[INIT] ({x},{y}) = {cell_content}")

    def run_selected_agent(self):
        agent_file = self.agent_var.get()
        if not agent_file:
            return
        self.run_agent(agent_file)
    
    def run_agent(self, agent_file):
        # Get selected map
        selected_map = self.map_var.get()
        if not selected_map:
            self.log_deduce("❌ Nessuna mappa selezionata")
            return

        self.reset()
        self.load_real_map(selected_map)
        
        import os
        work_dir = os.path.dirname(os.path.abspath(__file__))
        
        # First, load and show INIT cells from the selected map
        self.load_init_cells(selected_map)
        
        # Create batch with step-by-step output
        batch_content = f"""(load "0_Main.clp")
(load "1_Env.clp")
(load "{selected_map}")
(load "{agent_file}")
(reset)
(run)

;; Final state dump
(printout t "=== FINAL STATE ===" crlf)
(do-for-all-facts ((?f k-cell)) TRUE
    (printout t "INIT: [" ?f:x "," ?f:y "] = " ?f:content crlf)
)
(do-for-all-facts ((?f r-cell)) TRUE
    (printout t "RCELL: [" ?f:x "," ?f:y "] = " ?f:content crlf)
)
(exit)
"""
        
        batch_path = os.path.join(work_dir, 'temp_run.bat')
        with open(batch_path, 'w') as f:
            f.write(batch_content)
        
        try:
            result = subprocess.run(
                ['clipsdos', '-f', 'temp_run.bat'],
                capture_output=True,
                text=True,
                cwd=work_dir,
                timeout=15,
                encoding='cp1252', errors='replace'
            )
            
            self.parse_output(result.stdout)
            self.reveal_missed_ships()  # NEW: Reveal missing ships at end
            
        except Exception as e:
            self.log_deduce(f"❌ Errore: {e}")
        finally:
            # Cleanup temporary batch file
            if os.path.exists(batch_path):
                os.remove(batch_path)
    
    def parse_output(self, output):
        lines = output.split('\n')
        init_cells = set()
        
        for line in lines:
            # Parse DEDUCE messages (water deductions) - accept multiple formats
            if ('DEDUCE:' in line or '[DEDUCE]' in line) and 'water' in line:
                match = re.search(r'\[(\d+),\s*(\d+)\]\s*=\s*water', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    # Only show if not already INIT/FIRE/GUESS
                    if (x, y) not in self.cell_states or self.cell_states[(x, y)]['type'] == 'unknown':
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'deduced_water')
                        
                        # Extract reason
                        if 'row=0' in line:
                            self.log_deduce(f"[{x},{y}] = acqua (riga {x} vuota)")
                        elif 'col=0' in line:
                            self.log_deduce(f"[{x},{y}] = acqua (col {y} vuota)")
                        elif 'riga' in line and ('completa' in line or 'satura' in line):
                            self.log_deduce(f"[{x},{y}] = acqua (riga {x} satura)")
                        elif 'col' in line and ('completa' in line or 'satura' in line):
                            self.log_deduce(f"[{x},{y}] = acqua (col {y} satura)")
                        elif 'attorno' in line:
                            # Extract ship type
                            ship_match = re.search(r'attorno (\w+)\[(\d+),(\d+)\]', line)
                            if ship_match:
                                ship_type = ship_match.group(1)
                                sx, sy = ship_match.group(2), ship_match.group(3)
                                self.log_deduce(f"[{x},{y}] = acqua (vicino a {ship_type} in [{sx},{sy}])")
                        else:
                            self.log_deduce(f"[{x},{y}] = acqua")
                        
                        time.sleep(0.08)  # Slow animation for deductions
                continue
            
            # Parse INIT (k-cell iniziali) - ONLY for initial cells, NOT [LEARN]
            if 'INIT:' in line or '[INIT]' in line:
                match = re.search(r'\[(\d+),\s*(\d+)\]\s*=\s*(\w+)', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    content = match.group(3)
                    init_cells.add((x, y))
                    self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'init', content)
                    self.log_deduce(f"[INIT] ({x},{y}) = {content}")
                continue
            
            # Parse [LEARN] (discovered during gameplay via FIRE) - show as ship or water
            if '[LEARN]' in line:
                match = re.search(r'\[(\d+),\s*(\d+)\]\s*=\s*(\w+)', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    content = match.group(3)
                    if content == 'water':
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'deduced_water')
                        self.log_deduce(f"[{x},{y}] = acqua (scoperta)")
                    else:
                        # It's a ship part discovered by FIRE - already handled by FIRE parsing
                        pass
                continue
            
            # Parse FIRE - more flexible matching
            if ('FIRE' in line or 'Fire' in line or 'fire' in line) and 'Step' in line:
                match = re.search(r'\[(\d+),\s*(\d+)\]', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    self.fires_used += 1
                    self.fires_label.config(text=f"Fires: {self.fires_used}/5")
                    
                    # Determine if water or ship from real map
                    real_content = self.real_map.get((x, y), 'water')
                    if real_content == 'water':
                        self.fired_misses.add((x, y))
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'fire_water')
                        self.log_fire(f"[{x},{y}] → ACQUA")
                    else:
                        self.fired_hits.add((x, y))
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'fire_ship')
                        self.log_fire(f"[{x},{y}] → NAVE")
                    
                    time.sleep(0.4)  # Slower for FIRE
                continue
            
            # Parse GUESS
            if ('GUESS' in line or 'Guess' in line or 'guess' in line) and 'UNGUESS' not in line and 'Step' in line:
                match = re.search(r'\[(\d+),\s*(\d+)\]', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    self.guesses_used += 1
                    self.guesses_label.config(text=f"Guesses: {self.guesses_used}/20")
                    
                    # Check if guess is correct (ship in real map)
                    real_content = self.real_map.get((x, y), 'water')
                    if real_content == 'boat':
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'guess_correct')
                        self.log_guess(f"[{x},{y}] GUESS ✓ CORRETTO")
                    else:
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'guess_active')
                        self.log_guess(f"[{x},{y}] GUESS")
                    time.sleep(0.3)  # Slower for GUESS
                continue
            
            # Parse UNGUESS
            if 'UNGUESS' in line:
                match = re.search(r'\[(\d+),(\d+)\]', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    self.guesses_used -= 1
                    self.guesses_label.config(text=f"Guesses: {self.guesses_used}/20")
                    self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'unknown')
                    self.log_guess(f"[{x},{y}] UNGUESS")
                continue
            
            # Parse R-CELL (deduced)
            if 'RCELL:' in line:
                match = re.search(r'RCELL: \[(\d+),(\d+)\] = (\w+)', line)
                if match:
                    x, y = int(match.group(1)), int(match.group(2))
                    content = match.group(3)
                    
                    # Skip if already INIT/FIRE/GUESS
                    if (x, y) in init_cells:
                        continue
                    if (x, y) in self.cell_states and self.cell_states[(x, y)]['type'] in ['fire_water', 'fire_ship', 'guess_active']:
                        continue
                    
                    # Deduced
                    if content == 'water':
                        self.update_cell(self.agent_canvas, self.agent_cells, x, y, 'deduced_water')
                        self.log_deduce(f"[{x},{y}] = acqua (logica)")
                continue
            
            # Parse Step
            if 'Step' in line:
                match = re.search(r'Step (\d+)', line)
                if match:
                    self.step = int(match.group(1))
                    self.step_label.config(text=f"Step: {self.step}")
            
            # Parse Score
            if 'Your score is' in line:
                match = re.search(r'Your score is (-?\d+)', line)
                if match:
                    self.score = int(match.group(1))
                    self.score_label.config(text=f"Score: {self.score}")
    
    def log_fire(self, msg):
        self.fire_log.insert(tk.END, f"{msg}\n")
        self.fire_log.see(tk.END)
    
    def log_guess(self, msg):
        self.guess_log.insert(tk.END, f"{msg}\n")
        self.guess_log.see(tk.END)
    
    def log_deduce(self, msg):
        self.deduce_log.insert(tk.END, f"{msg}\n")
        self.deduce_log.see(tk.END)
    
    def reset(self):
        self.step = 0
        self.score = 0
        self.fires_used = 0
        self.guesses_used = 0
        self.cell_states = {}
        self.fired_hits = set()
        self.fired_misses = set()
        self.k_per_row = {}
        self.k_per_col = {}
        self.real_map = {}
        
        self.step_label.config(text="Step: 0")
        self.score_label.config(text="Score: 0")
        self.fires_label.config(text="Fires: 0/5")
        self.guesses_label.config(text="Guesses: 0/20")
        
        self.fire_log.delete(1.0, tk.END)
        self.guess_log.delete(1.0, tk.END)
        self.deduce_log.delete(1.0, tk.END)
        
        self.agent_cells = {}
        self.real_cells = {}
        self.draw_grid(self.agent_canvas, self.agent_cells)
        self.draw_grid(self.real_canvas, self.real_cells)

if __name__ == "__main__":
    root = tk.Tk()
    app = BattleshipVisualizerAdvanced(root)
    root.mainloop()
