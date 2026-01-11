import tkinter as tk
from tkinter import messagebox, ttk, scrolledtext
import subprocess
import os
import re
import random
import time
import threading
import shutil

# Path to the directory containing Prolog files
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOMINIO_FILE = os.path.join(BASE_DIR, "dominioP8.pl")

# --- Theme Configuration ---
THEME = {
    "bg_main": "#ECF0F1",        # Light Grey BG
    "bg_sidebar": "#2C3E50",     # Dark Blue Sidebar
    "fg_sidebar": "#ECF0F1",     # White Text
    "accent_color": "#E67E22",   # Orange Buttons
    "control_btn": "#3498DB",    # Blue Controls
    "highlight_bg": "#F39C12",   # Highlight
    "tile_bg": "#F1C40F",        # Yellow (User Preference)
    "tile_fg": "#2980B9",        # Blue Numbers
    "tile_empty": "#95A5A6",     # Grey Empty
    "font_title": ("Helvetica", 18, "bold"),
    "font_label": ("Helvetica", 11),
    "font_log": ("Consolas", 10),
}

class PuzzleGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("8-Puzzle Solver AI")
        self.root.geometry("1000x700")
        self.root.configure(bg=THEME["bg_main"])

        self.setup_styles()
        
        self.root.columnconfigure(0, weight=1)
        self.root.columnconfigure(1, weight=0)
        self.root.rowconfigure(0, weight=1)

        # State initialization
        self.initial_state_scanned = self.load_initial_state_from_file()
        self.current_state = list(self.initial_state_scanned)
        self.solution_path = []
        
        # detailed state
        self.solution_step_index = 0
        self.is_playing = False
        self.animation_job = None
        self.log_lines_map = {} # Maps step index to line number in log
        
        self.create_widgets()

    def load_initial_state_from_file(self):
        default_state = [1, 2, 3, 4, 5, 6, 7, 8, 'e']
        try:
            if os.path.exists(DOMINIO_FILE):
                with open(DOMINIO_FILE, 'r') as f:
                    content = f.read()
                match = re.search(r"initial_state\(\[(.*?)\]\)", content)
                if match:
                    items_str = match.group(1).split(',')
                    items = []
                    for it in items_str:
                        it = it.strip()
                        if it == 'e': items.append('e')
                        else: items.append(int(it))
                    if len(items) == 9:
                        print(f"Loaded initial state: {items}")
                        return items
        except Exception as e:
            print(f"Error loading initial state: {e}")
        return default_state

    def setup_styles(self):
        self.style = ttk.Style()
        self.style.theme_use('clam')
        
        self.style.configure(
            "TButton", 
            font=("Helvetica", 10, "bold"), 
            background=THEME["accent_color"], 
            foreground="white", 
            borderwidth=0, 
            padding=8
        )
        self.style.map("TButton", background=[("active", "#D35400")])
        
        self.style.configure(
            "Control.TButton", 
            background=THEME["control_btn"],
            padding=5
        )
        self.style.map("Control.TButton", background=[("active", "#2980B9")])

    def create_widgets(self):
        # 1. Puzzle Area - RESPONSIVE CONTAINER
        self.puzzle_frame = tk.Frame(self.root, bg=THEME["bg_main"])
        self.puzzle_frame.grid(row=0, column=0, sticky="nsew")
        self.puzzle_frame.rowconfigure(0, weight=1)
        self.puzzle_frame.columnconfigure(0, weight=1)

        # Wrapper for the square grid
        self.center_wrapper = tk.Frame(self.puzzle_frame, bg=THEME["bg_main"])
        self.center_wrapper.grid(row=0, column=0, sticky="nsew", padx=20, pady=20)
        
        # The actual Grid Container (Square)
        # We will use .place() in on_resize to keep it square and centered
        self.grid_container = tk.Frame(self.center_wrapper, bg="#7F8C8D", padx=5, pady=5)
        
        # Configure grid 3x3 inside the container
        for i in range(3):
            self.grid_container.rowconfigure(i, weight=1)
            self.grid_container.columnconfigure(i, weight=1)
        
        self.tiles = []
        for r in range(3):
            row_tiles = []
            for c in range(3):
                tile_frame = tk.Frame(self.grid_container, bg="#BDC3C7", padx=2, pady=2)
                tile_frame.grid(row=r, column=c, padx=2, pady=2, sticky="nsew")
                tile_frame.rowconfigure(0, weight=1)
                tile_frame.columnconfigure(0, weight=1)
                
                tile = tk.Label(
                    tile_frame, 
                    text="", 
                    bg=THEME["tile_bg"], 
                    fg=THEME["tile_fg"],
                    relief="flat"
                )
                tile.grid(row=0, column=0, sticky="nsew")
                row_tiles.append(tile)
            self.tiles.append(row_tiles)
            
        # Bind resize event to center_wrapper to adjust grid_container size strictly
        self.center_wrapper.bind('<Configure>', self.on_resize)
        
        self.update_grid_ui(self.current_state)

        # 2. Sidebar
        self.controls_frame = tk.Frame(self.root, bg=THEME["bg_sidebar"], width=350)
        self.controls_frame.grid(row=0, column=1, sticky="nsew")
        self.controls_frame.grid_propagate(False)

        title_lbl = tk.Label(
            self.controls_frame, 
            text="8-PUZZLE SOLVER", 
            font=THEME["font_title"], 
            bg=THEME["bg_sidebar"], 
            fg="white", 
            justify="center"
        )
        title_lbl.pack(pady=(25, 20))

        opts_frame = tk.Frame(self.controls_frame, bg=THEME["bg_sidebar"])
        opts_frame.pack(fill="x", padx=20)

        ttk.Button(opts_frame, text="🔄 Reset to File Default", command=self.reset_to_file_default).pack(fill="x", pady=2)
        ttk.Button(opts_frame, text="🎲 Randomize Puzzle", command=self.randomize_puzzle).pack(fill="x", pady=2)
        
        tk.Label(opts_frame, text="Algorithms", bg=THEME["bg_sidebar"], fg="#95A5A6", font=("Helvetica", 10, "bold")).pack(pady=(20, 5), anchor="w")
        
        btn_frame = tk.Frame(opts_frame, bg=THEME["bg_sidebar"])
        btn_frame.pack(fill="x")
        ttk.Button(btn_frame, text="Solve A*", command=lambda: self.solve("a_star")).pack(side="left", fill="x", expand=True, padx=(0, 2))
        ttk.Button(btn_frame, text="Solve IDA*", command=lambda: self.solve("ida_star")).pack(side="right", fill="x", expand=True, padx=(2, 0))

        # Playback Controls
        tk.Label(opts_frame, text="Playback Controls", bg=THEME["bg_sidebar"], fg="#95A5A6", font=("Helvetica", 10, "bold")).pack(pady=(20, 5), anchor="w")
        
        play_frame = tk.Frame(opts_frame, bg=THEME["bg_sidebar"])
        play_frame.pack(fill="x")
        
        self.btn_prev = ttk.Button(play_frame, text="<", width=3, style="Control.TButton", command=self.prev_step, state="disabled")
        self.btn_prev.pack(side="left", padx=2)
        
        self.btn_play_pause = ttk.Button(play_frame, text="▶", width=4, style="Control.TButton", command=self.toggle_play_pause, state="disabled")
        self.btn_play_pause.pack(side="left", padx=2, fill="x", expand=True)

        self.btn_next = ttk.Button(play_frame, text=">", width=3, style="Control.TButton", command=self.next_step, state="disabled")
        self.btn_next.pack(side="left", padx=2)

        self.speed_scale = ttk.Scale(opts_frame, from_=0.1, to=1.0, value=0.6)
        self.speed_scale.pack(fill="x", pady=(10,0))

        # Status
        self.status_var = tk.StringVar(value="Ready to play")
        status_lbl = tk.Label(opts_frame, textvariable=self.status_var, bg=THEME["bg_sidebar"], fg="#F1C40F", font=("Helvetica", 11, "italic"), wraplength=300)
        status_lbl.pack(pady=20)

        tk.Label(self.controls_frame, text="Solution Log", bg=THEME["bg_sidebar"], fg="white", font=("Helvetica", 12, "bold")).pack(pady=(5, 5), anchor="s")
        
        self.log_text = scrolledtext.ScrolledText(
            self.controls_frame, 
            height=12, 
            bg="#34495E", 
            fg="#ECF0F1", 
            font=THEME["font_log"],
            relief="flat",
            padx=10,
            pady=10
        )
        self.log_text.tag_config("highlight", background=THEME["highlight_bg"], foreground="white")
        self.log_text.pack(fill="both", expand=True, padx=20, pady=(0, 20))
        self.log_message("Waiting for solution...")
        self.log_text.configure(state='disabled')

    def on_resize(self, event):
        # Determine the maximum square size that fits
        w = event.width
        h = event.height
        
        # Padding applied in center_wrapper is 20+20=40, handled by the wrapper size itself roughly,
        # but let's just take the events from wrapper.
        size = min(w, h)
        if size < 200: size = 200 # Minimum size
        
        # Center the grid_container with explicit square size
        self.grid_container.place(relx=0.5, rely=0.5, anchor="center", width=size, height=size)
        
        # Font scaling
        font_size = max(20, size // 3 // 2)
        new_font = ("Helvetica", font_size, "bold")
        
        for r in range(3):
            for c in range(3):
                self.tiles[r][c].configure(font=new_font)

    def update_grid_ui(self, state):
        for i, val in enumerate(state):
            r, c = divmod(i, 3)
            if val == 'e':
                self.tiles[r][c].config(text="", bg=THEME["tile_empty"])
            else:
                self.tiles[r][c].config(text=str(val), bg=THEME["tile_bg"])

    def set_playback_controls_state(self, state):
        self.btn_prev.config(state=state)
        self.btn_next.config(state=state)
        self.btn_play_pause.config(state=state)

    def reset_to_file_default(self):
        self.stop_animation()
        self.initial_state_scanned = self.load_initial_state_from_file()
        self.current_state = list(self.initial_state_scanned)
        self.update_grid_ui(self.current_state)
        self.solution_path = []
        self.log_message("Reset to file default.", clear=True)
        self.status_var.set("Reset to Default")
        self.set_playback_controls_state("disabled")

    def randomize_puzzle(self):
        self.stop_animation()
        state = [1, 2, 3, 4, 5, 6, 7, 8, 'e']
        for _ in range(40):
            idx = state.index('e')
            possibles = []
            if idx >= 3: possibles.append(idx - 3)
            if idx <= 5: possibles.append(idx + 3)
            if idx % 3 > 0: possibles.append(idx - 1)
            if idx % 3 < 2: possibles.append(idx + 1)
            
            swap_idx = random.choice(possibles)
            state[idx], state[swap_idx] = state[swap_idx], state[idx]
        
        self.current_state = state
        self.update_grid_ui(self.current_state)
        self.solution_path = []
        self.log_message("Puzzle Randomized.", clear=True)
        self.status_var.set("Randomized")
        self.set_playback_controls_state("disabled")

    def log_message(self, msg, clear=False):
        self.log_text.configure(state='normal')
        if clear:
            self.log_text.delete(1.0, "end")
        self.log_text.insert("end", msg + "\n")
        self.log_text.see("end")
        self.log_text.configure(state='disabled')

    def calculate_human_readable_move(self, prev, curr):
        prev_e = prev.index('e')
        curr_e = curr.index('e')
        if prev_e == curr_e: return None
        
        moved_piece = curr[prev_e]
        pr, pc = divmod(prev_e, 3) 
        cr, cc = divmod(curr_e, 3)
        
        direction = "UNKNOWN"
        if cr < pr: direction = "DOWN"
        elif cr > pr: direction = "UP"
        elif cc < pc: direction = "RIGHT"
        elif cc > pc: direction = "LEFT"
        
        return f"Tile {moved_piece} {direction}"

    def solve(self, algorithm):
        self.stop_animation()
        self.status_var.set(f"Running {algorithm}...")
        self.log_message(f"--- Starting {algorithm} ---", clear=True)
        self.root.update()
        threading.Thread(target=self._run_prolog_thread, args=(algorithm,)).start()

    def _run_prolog_thread(self, algorithm):
        try:
            temp_dominio = os.path.join(BASE_DIR, "temp_dominio.pl")
            temp_runner = os.path.join(BASE_DIR, "temp_runner.pl")
            
            with open(DOMINIO_FILE, 'r') as f: content = f.read()
            
            state_str = "[" + ",".join(str(x) for x in self.current_state) + "]"
            new_content = re.sub(r"initial_state\(\[.*?\]\)\.", f"initial_state({state_str}).", content)
            
            with open(temp_dominio, 'w') as f: f.write(new_content)
                
            runner_code = f"""
            :- [temp_dominio, utils, regole, heuristic, {algorithm}].
            run_solve :-
                get_time(Start),
                {algorithm}(Path, Cost),
                get_time(End),
                Time is End - Start,
                write('START_RESULT'), nl,
                write(Path), nl,
                write(Cost), nl,
                write(Time), nl,
                write('END_RESULT'), nl,
                halt.
            """
            with open(temp_runner, 'w') as f: f.write(runner_code)
            
            cmd = ["swipl", "-s", "temp_runner.pl", "-g", "run_solve"]
            result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
            
            if result.returncode != 0: raise Exception(f"Prolog Error")
            output = result.stdout
            
            if "START_RESULT" not in output:
                if "No solution" in output:
                     self.root.after(0, lambda: self.log_message("No solution found.", clear=True))
                     self.root.after(0, lambda: self.status_var.set("No solution"))
                     return
                raise Exception("Parse Error")
                
            parts = output.split("START_RESULT")[1].split("END_RESULT")[0].strip().splitlines()
            path_str = parts[0].strip().replace("e", "'e'")
            try: solution_path = eval(path_str)
            except: 
                path_str = re.sub(r'\b([a-z])\b', r"'\1'", path_str)
                solution_path = eval(path_str)
                
            self.root.after(0, lambda: self.start_solution_playback(solution_path, parts[1], parts[2]))

        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
        finally:
            if os.path.exists(temp_dominio): os.remove(temp_dominio)
            if os.path.exists(temp_runner): os.remove(temp_runner)

    def start_solution_playback(self, path, cost, time_taken):
        self.solution_path = path
        self.solution_step_index = 0
        self.status_var.set(f"Solved! Moves: {cost} | Time: {float(time_taken):.3f}s")
        
        # Populate Log Step 1: Clear
        self.log_text.configure(state='normal')
        self.log_text.delete(1.0, "end")
        
        self.log_lines_map = {}
        # Header
        self.log_text.insert("end", f"Solution found in {cost} moves.\n")
        self.log_text.insert("end", "0. Initial State\n")
        self.log_lines_map[0] = 2 # Line 2
        
        # Fill rest
        current_line = 3
        for i in range(1, len(path)):
            prev = path[i-1]
            curr = path[i]
            move_str = self.calculate_human_readable_move(prev, curr)
            msg = f"{i}. {move_str}\n"
            self.log_text.insert("end", msg)
            self.log_lines_map[i] = current_line
            current_line += 1
            
        self.log_text.configure(state='disabled')
        
        self.set_playback_controls_state("normal")
        self.play()

    def toggle_play_pause(self):
        if self.is_playing:
            self.pause()
        else:
            self.play()

    def play(self):
        if not self.solution_path: return
        self.is_playing = True
        self.btn_play_pause.config(text="❚❚")
        self.animate_loop()

    def pause(self):
        self.is_playing = False
        self.btn_play_pause.config(text="▶")
        if self.animation_job:
            self.root.after_cancel(self.animation_job)
            self.animation_job = None

    def stop_animation(self):
        self.pause()
        self.solution_step_index = 0

    def animate_loop(self):
        if not self.is_playing: return
        
        if self.solution_step_index < len(self.solution_path) - 1:
            self.next_step(auto=True)
            delay = int((1.1 - self.speed_scale.get()) * 800)
            self.animation_job = self.root.after(delay, self.animate_loop)
        else:
            self.pause()

    def next_step(self, auto=False):
        if self.solution_path and self.solution_step_index < len(self.solution_path) - 1:
            self.solution_step_index += 1
            self.update_ui_state_at_current_step()
            if not auto: self.pause()

    def prev_step(self):
        if self.solution_path and self.solution_step_index > 0:
            self.solution_step_index -= 1
            self.update_ui_state_at_current_step()
            self.pause()

    def update_ui_state_at_current_step(self):
        if not self.solution_path: return

        curr = self.solution_path[self.solution_step_index]
        self.current_state = curr
        self.update_grid_ui(curr)
        
        # Log Highlight
        self.log_text.configure(state='normal')
        self.log_text.tag_remove("highlight", 1.0, "end")
        
        line_num = self.log_lines_map.get(self.solution_step_index)
        if line_num:
            start_idx = f"{line_num}.0"
            end_idx = f"{line_num + 1}.0"
            self.log_text.tag_add("highlight", start_idx, end_idx)
            self.log_text.see(start_idx)
            
        self.log_text.configure(state='disabled')

if __name__ == "__main__":
    root = tk.Tk()
    app = PuzzleGUI(root)
    root.mainloop()
