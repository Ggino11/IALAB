import tkinter as tk
from tkinter import messagebox, ttk, filedialog
import subprocess
import os
import re
import threading
import time

# Base directory for the labyrinth project
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# If we are already in the Labirinto folder
if os.path.basename(BASE_DIR) == "Labirinto":
    LABIRINTO_DIR = BASE_DIR
else:
    LABIRINTO_DIR = os.path.join(BASE_DIR, "Labirinto")

THEME = {
    "bg_main": "#ECF0F1",
    "bg_sidebar": "#2C3E50",
    "fg_sidebar": "#ECF0F1",
    "accent_color": "#E67E22",
    "control_btn": "#3498DB",
    # Map Colors
    "color_empty": "#FFFFFF",
    "color_wall": "#2C3E50",
    "color_start": "#3498DB", # Blue
    "color_goal": "#E74C3C",  # Red
    "color_visit": "#F1C40F", # Yellow/Orange for visited nodes
    "color_path": "#2ECC71",  # Green for solution
    "color_frontier": "#9B59B6" # Purple for currently expanding
}

class LabyrinthGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Labyrinth Solver AI")
        self.root.geometry("1100x800")
        self.root.configure(bg=THEME["bg_main"])

        # Data
        self.map_data = {
            "rows": 0, "cols": 0,
            "start": None, "goals": [],
            "walls": set()
        }
        self.map_loaded = False
        
        # Simulation Data
        self.visits_log = [] # List of visited states in order
        self.solution_path = [] # Final path
        self.is_playing = False
        self.sim_index = 0 # Current step in visits_log + solution_path
        self.animation_job = None
        self.sim_speed = 0.05 # Delay in seconds

        self.setup_ui()

    def setup_ui(self):
        # 1. Main Layout: Canvas (Left) + Sidebar (Right)
        self.root.columnconfigure(0, weight=1)
        self.root.columnconfigure(1, weight=0)
        self.root.rowconfigure(0, weight=1)

        # Content Area (for Canvas)
        self.content_frame = tk.Frame(self.root, bg=THEME["bg_main"])
        self.content_frame.grid(row=0, column=0, sticky="nsew", padx=20, pady=20)
        
        # Canvas wrapper to center
        self.canvas_wrapper = tk.Frame(self.content_frame, bg=THEME["bg_main"])
        self.canvas_wrapper.pack(expand=True, fill="both")
        
        self.canvas = tk.Canvas(self.canvas_wrapper, bg=THEME["color_empty"], highlightthickness=0)
        self.canvas.place(relx=0.5, rely=0.5, anchor="center")

        # 2. Sidebar
        self.sidebar = tk.Frame(self.root, bg=THEME["bg_sidebar"], width=350)
        self.sidebar.grid(row=0, column=1, sticky="nsew")
        self.sidebar.grid_propagate(False)

        # Title
        tk.Label(self.sidebar, text="MAZE SOLVER", font=("Helvetica", 16, "bold"), 
                 bg=THEME["bg_sidebar"], fg="white").pack(pady=(20, 20))

        # File Selection
        btn_load = ttk.Button(self.sidebar, text="📂 Load Map (.pl)", command=self.load_map_dialog)
        btn_load.pack(fill="x", padx=20, pady=5)
        
        self.lbl_map_info = tk.Label(self.sidebar, text="No map loaded", bg=THEME["bg_sidebar"], fg="#BDC3C7")
        self.lbl_map_info.pack(pady=5)

        # Algorithms
        tk.Label(self.sidebar, text="Algorithms", bg=THEME["bg_sidebar"], fg="#95A5A6", font=("Helvetica", 10, "bold")).pack(pady=(20, 5), anchor="w", padx=20)
        
        frame_algo = tk.Frame(self.sidebar, bg=THEME["bg_sidebar"])
        frame_algo.pack(fill="x", padx=20)
        
        self.btn_astar = ttk.Button(frame_algo, text="Result: A*", command=lambda: self.run_solver("a_star"), state="disabled")
        self.btn_astar.pack(side="left", fill="x", expand=True, padx=(0, 2))
        
        self.btn_idastar = ttk.Button(frame_algo, text="Result: IDA*", command=lambda: self.run_solver("ida_star"), state="disabled")
        self.btn_idastar.pack(side="right", fill="x", expand=True, padx=(2, 0))

        # Simulation Controls
        tk.Label(self.sidebar, text="Simulation", bg=THEME["bg_sidebar"], fg="#95A5A6", font=("Helvetica", 10, "bold")).pack(pady=(20, 5), anchor="w", padx=20)

        ctrl_frame = tk.Frame(self.sidebar, bg=THEME["bg_sidebar"])
        ctrl_frame.pack(fill="x", padx=20)

        self.btn_prev = ttk.Button(ctrl_frame, text="<", width=3, command=self.step_prev, state="disabled")
        self.btn_prev.pack(side="left", padx=2)
        
        self.btn_play = ttk.Button(ctrl_frame, text="▶", width=5, command=self.toggle_play, state="disabled")
        self.btn_play.pack(side="left", fill="x", expand=True, padx=2)
        
        self.btn_next = ttk.Button(ctrl_frame, text=">", width=3, command=self.step_next, state="disabled")
        self.btn_next.pack(side="left", padx=2)

        # Speed Slider
        tk.Label(self.sidebar, text="Speed", bg=THEME["bg_sidebar"], fg="white", font=("Helvetica", 9)).pack(pady=(10,0))
        self.scale_speed = ttk.Scale(self.sidebar, from_=0.01, to=0.5, value=0.05, command=self.update_speed)
        self.scale_speed.pack(fill="x", padx=20, pady=5)
        
        # Stats
        self.lbl_stats = tk.Label(self.sidebar, text="", bg=THEME["bg_sidebar"], fg="#F1C40F", justify="left")
        self.lbl_stats.pack(pady=20, padx=20, anchor="w")

        # Log
        self.log_text = tk.Text(self.sidebar, height=15, bg="#34495E", fg="#ECF0F1", font=("Consolas", 8), relief="flat")
        self.log_text.pack(fill="both", expand=True, padx=20, pady=20)

    def update_speed(self, val):
        # Slider value: 0.01 (Fast) -> 0.5 (Slow)
        # But user intuition is Right = Fast usually, or Left = Slow. 
        # Let's make Left (0.01) = Super Fast, Right (0.5) = Slow.
        self.sim_speed = float(val)

    def log(self, msg):
        self.log_text.insert("end", msg + "\n")
        self.log_text.see("end")

    def load_map_dialog(self):
        path = filedialog.askopenfilename(
            initialdir=LABIRINTO_DIR if os.path.exists(LABIRINTO_DIR) else BASE_DIR,
            filetypes=[("Prolog Files", "*.pl")]
        )
        if path:
            self.parse_map(path)

    def parse_map(self, filepath):
        try:
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Reset Data
            self.map_data = {"rows": 0, "cols": 0, "start": None, "goals": [], "walls": set()}
            
            # Parse Regex
            row_match = re.search(r"num_righe\((\d+)\)\.", content)
            col_match = re.search(r"num_colonne\((\d+)\)\.", content)
            
            if row_match: self.map_data["rows"] = int(row_match.group(1))
            if col_match: self.map_data["cols"] = int(col_match.group(1))
            
            # COORD FIX: Prolog pos(Row, Col). Python Canvas (x, y) = (Col, Row).
            # So pos(A, B) -> x=B-1, y=A-1.
            
            start_match = re.search(r"iniziale\(pos\((\d+),(\d+)\)\)\.", content)
            if start_match:
                # Group1=Row, Group2=Col
                r, c = int(start_match.group(1)), int(start_match.group(2))
                self.map_data["start"] = (c-1, r-1)
                
            goal_iter = re.finditer(r"finale\(pos\((\d+),(\d+)\)\)\.", content)
            for m in goal_iter:
                r, c = int(m.group(1)), int(m.group(2))
                self.map_data["goals"].append((c-1, r-1))
                
            wall_iter = re.finditer(r"occupata\(pos\((\d+),(\d+)\)\)\.", content)
            for m in wall_iter:
                r, c = int(m.group(1)), int(m.group(2))
                self.map_data["walls"].add((c-1, r-1))
                
            self.map_loaded = True
            self.lbl_map_info.config(text=f"Items: {os.path.basename(filepath)}\nSize: {self.map_data['rows']}x{self.map_data['cols']}")
            
            self.draw_grid()
            self.btn_astar.config(state="normal")
            self.btn_idastar.config(state="normal")
            self.log(f"Loaded map: {os.path.basename(filepath)}")
            
            self.current_map_path = filepath
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to parse map: {e}")

    def process_result(self, stdout, stderr, returncode, algo):
        # ALWAYS Log RAW output for debugging
        self.log(f"--- DEBUG: RAW OUTPUT ({algo}) ---")
        self.log(f"Return Code: {returncode}")
        if stderr: self.log(f"STDERR:\n{stderr}")
        if stdout: 
            self.log(f"STDOUT (First 500 chars):\n{stdout[:500]}...")
            if len(stdout) > 500: self.log(f"STDOUT (Last 200 chars):\n...{stdout[-200:]}")
        else:
            self.log("STDOUT is EMPTY.")
        self.log("-----------------------------------")
        
        visits = []
        path = []
        
        # 1. Parse Visits
        # VISIT: pos(Row, Col). Map to x=Col-1, y=Row-1
        visit_pattern = re.compile(r"VISIT:\s*pos\((\d+),(\d+)\)")
        for line in stdout.splitlines():
            m = visit_pattern.search(line)
            if m:
                r, c = int(m.group(1)), int(m.group(2))
                visits.append((c-1, r-1))
        
        # 2. Parse Solution
        sol_match = re.search(r"Path: (\[.*?\])", stdout)
        if sol_match:
            try:
                raw_list = sol_match.group(1)
                if "pos(" in raw_list:
                    p_items = re.findall(r"pos\((\d+),(\d+)\)", raw_list)
                    path = [(int(c)-1, int(r)-1) for r, c in p_items]
                else:
                    content = raw_list.strip("[]")
                    if content:
                        actions = [x.strip() for x in content.split(',')]
                        path = self.reconstruct_path(actions)
            except Exception as e:
                self.log(f"Error parsing path: {e}")

        self.visits_log = visits
        self.solution_path = path

        self.log(f"Parsed {len(visits)} visited nodes.")
        self.log(f"Path length: {len(path)}")
        
        self.lbl_stats.config(text=f"Visited: {len(visits)} | Path: {len(path)}")
        
        self.sim_index = 0
        self.is_playing = False
        
        if visits or path:
            self.btn_play.config(state="normal")
            self.btn_prev.config(state="normal")
            self.btn_next.config(state="normal")
            self.draw_grid()
            self.start_animation()
            
    def reconstruct_path(self, actions):
        if not self.map_data["start"]: return []
        
        # Start is (x, y) = (col, row)
        current = self.map_data["start"]
        path_coords = [current]
        
        for act in actions:
            x, y = current 
            
            # Actions:
            # nord: Row-1 => y-1
            # sud: Row+1 => y+1
            # est: Col+1 => x+1
            # ovest: Col-1 => x-1
            
            if act == 'nord':
                y -= 1
            elif act == 'sud':
                y += 1
            elif act == 'est':
                x += 1
            elif act == 'ovest':
                x -= 1
            
            current = (x, y)
            path_coords.append(current)
            
        return path_coords

    def draw_grid(self):
        self.canvas.delete("all")
        rows = self.map_data["rows"]
        cols = self.map_data["cols"]
        if rows == 0 or cols == 0: return

        # Calculate cell size
        # Canvas wrapper dimensions? It might be small initially.
        cw = self.canvas_wrapper.winfo_width()
        ch = self.canvas_wrapper.winfo_height()
        if cw < 50: cw = 600
        if ch < 50: ch = 600
        
        max_w = cw - 40
        max_h = ch - 40
        
        cell_w = max_w // cols
        cell_h = max_h // rows
        self.cell_size = min(cell_w, cell_h)
        
        # Resize canvas
        self.canvas.config(width=self.cell_size * cols, height=self.cell_size * rows)
        
        # Draw cells
        for r in range(rows):
            for c in range(cols):
                x1 = c * self.cell_size
                y1 = r * self.cell_size
                x2 = x1 + self.cell_size
                y2 = y1 + self.cell_size
                
                # Determine color
                color = THEME["color_empty"]
                if (c, r) in self.map_data["walls"]:
                    color = THEME["color_wall"]
                elif (c, r) == self.map_data["start"]:
                    color = THEME["color_start"]
                elif (c, r) in self.map_data["goals"]:
                    color = THEME["color_goal"]
                    
                self.canvas.create_rectangle(x1, y1, x2, y2, fill=color, outline="#BDC3C7", tags=f"cell_{c}_{r}")
    
    def run_solver(self, algo):
        if not self.map_loaded: return
        self.btn_astar.config(state="disabled")
        self.btn_idastar.config(state="disabled")
        self.log(f"Solving with {algo}...")
        
        threading.Thread(target=self._solve_thread, args=(algo,)).start()

    def _solve_thread(self, algo):
        try:
            # 1. Create Runner File
            temp_algo_file = os.path.join(LABIRINTO_DIR, f"temp_{algo}.pl")
            algo_source = os.path.join(LABIRINTO_DIR, f"{algo}.pl")
            
            with open(algo_source, 'r') as f:
                code = f.read()
            
            # INSTRUMENTATION - Use format for strict output
            if algo == "a_star":
                # Inject before NewClosed
                pattern = r"(NewClosed\s*=\s*\[CurrentState\|Closed\],)"
                # Use format for clean output: VISIT:pos(1,2)
                # Wait, CurrentState is pos(R,C). We need to extract R,C?
                # Actually write(CurrentState) outputs pos(1,2).
                # But to be safe lets use write(CurrentState).
                # Let's trust write but allow spaces in Regex.
                replacement = r"write('VISIT:'), write(CurrentState), nl, \1"
                
                new_code, count = re.subn(pattern, replacement, code)
                if count == 0:
                    print("WARNING: Failed to inject probe in a_star")
                code = new_code
                
            elif algo == "ida_star":
                pattern = r"(assertz\(ida_visited\(State,\s*G\)\),)"
                replacement = r"\1 write('VISIT:'), write(State), nl,"
                
                new_code, count = re.subn(pattern, replacement, code)
                if count == 0:
                    print("WARNING: Failed to inject probe in ida_star")
                code = new_code
            
            with open(temp_algo_file, 'w') as f:
                f.write(code)
            
            # Create Runner
            runner_file = os.path.join(LABIRINTO_DIR, "temp_runner.pl")
            
            # Normalize path for Prolog
            map_path_pl = self.current_map_path.replace("\\", "/")
            
            runner_code = f"""
            :- ['{map_path_pl}'].
            :- [azioni, heuristic, 'temp_{algo}'].
            
            run :-
                (
                    current_predicate(runAStar/0) -> runAStar ;
                    current_predicate(runIDAStar/0) -> runIDAStar
                ),
                halt.
            """
            
            with open(runner_file, 'w') as f:
                f.write(runner_code)
            
            # Run SWIPL
            cmd = ["swipl", "-s", "temp_runner.pl", "-g", "run"]
            
            # DEBUG: print command
            print(f"Executing: {cmd} in {LABIRINTO_DIR}")
            
            res = subprocess.run(cmd, cwd=LABIRINTO_DIR, capture_output=True, text=True, encoding='utf-8')
            
            # Clean up (commented out for debug if needed, but keeping for now)
            try:
                os.remove(temp_algo_file)
                os.remove(runner_file)
            except: pass
            
            # ALWAYS process result to show stdout/stderr logs in GUI
            self.root.after(0, lambda: self.process_result(res.stdout, res.stderr, res.returncode, algo))

        except Exception as e:
            print(f"Exception: {e}")
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
        finally:
            self.root.after(0, lambda: self.enable_buttons())

    def enable_buttons(self):
        self.btn_astar.config(state="normal")
        self.btn_idastar.config(state="normal")

    def process_result(self, stdout, stderr, returncode, algo):
        self.log(f"--- DEBUG: RAW OUTPUT ({algo}) ---")
        self.log(f"Return Code: {returncode}")
        if stderr: self.log(f"STDERR:\n{stderr}")
        if stdout: 
            self.log(f"STDOUT (First 500 chars):\n{stdout[:500]}...")
            if len(stdout) > 500: self.log(f"STDOUT (Last 200 chars):\n...{stdout[-200:]}")
        else:
            self.log("STDOUT is EMPTY.")
        self.log("-----------------------------------")
        
        visits = []
        path = []
        
        # 1. Parse Visits
        # Correct Logic:
        # Prolog Output: VISIT: pos(Row, Col)
        # Regex Groups: (Row), (Col)
        # Store: (x, y) = (Col-1, Row-1)
        
        visit_pattern = re.compile(r"VISIT:\s*pos\(\s*(\d+)\s*,\s*(\d+)\s*\)")
        for line in stdout.splitlines():
            m = visit_pattern.search(line)
            if m:
                r_val = int(m.group(1))
                c_val = int(m.group(2))
                visits.append((c_val - 1, r_val - 1))
        
        # 2. Parse Solution
        sol_match = re.search(r"Path: (\[.*?\])", stdout)
        if sol_match:
            try:
                raw_list = sol_match.group(1)
                if "pos(" in raw_list:
                    p_items = re.findall(r"pos\((\d+),(\d+)\)", raw_list)
                    # p_items has (Row, Col) tuples
                    path = [(int(c)-1, int(r)-1) for r, c in p_items]
                else:
                    content = raw_list.strip("[]")
                    if content:
                        actions = [x.strip() for x in content.split(',')]
                        path = self.reconstruct_path(actions)
            except Exception as e:
                self.log(f"Error parsing path: {e}")

        self.visits_log = visits
        self.solution_path = path

        self.log(f"Parsed {len(visits)} visited nodes.")
        if visits:
            self.log(f"First 5 visits: {visits[:5]}")
            self.log(f"Last 5 visits: {visits[-5:]}")
            
        self.log(f"Path length: {len(path)}")
        if path:
             self.log(f"Path Start: {path[0]}")
             self.log(f"Path End: {path[-1]}")
        
        self.lbl_stats.config(text=f"Visited: {len(visits)} | Path: {len(path)}")
        
        self.sim_index = 0
        self.is_playing = False
        
        if visits or path:
            self.btn_play.config(state="normal")
            self.btn_prev.config(state="normal")
            self.btn_next.config(state="normal")
            self.draw_grid()
            self.start_animation()
            
    def reconstruct_path(self, actions):
        # Start from map Start
        if not self.map_data["start"]: return []
        
        current = self.map_data["start"] # (col, row) 0-based
        path_coords = [current]
        
        for act in actions:
            c, r = current
            # Actions based on azioni.pl logic
            # Action list usually: nord, sud, est, ovest
            # Prolog logic: row, col. 1-based.
            # Python grid: (c, r) = (x, y)
            # nord: r-1
            # sud: r+1
            # est: c+1
            # ovest: c-1
            
            if act == 'nord':
                r -= 1
            elif act == 'sud':
                r += 1
            elif act == 'est':
                c += 1
            elif act == 'ovest':
                c -= 1
            
            current = (c, r)
            path_coords.append(current)
            
        return path_coords

    def start_animation(self):
        self.is_playing = True
        self.btn_play.config(text="❚❚")
        self.animate_loop()

    def toggle_play(self):
        if self.is_playing:
            self.is_playing = False
            self.btn_play.config(text="▶")
            if self.animation_job:
                self.root.after_cancel(self.animation_job)
                self.animation_job = None
        else:
            self.is_playing = True
            self.btn_play.config(text="❚❚")
            self.animate_loop()

    def step_next(self):
        self.is_playing = False
        self.btn_play.config(text="▶")
        self.do_step(1)

    def step_prev(self):
        self.is_playing = False
        self.btn_play.config(text="▶")
        self.do_step(-1)

    def animate_loop(self):
        if not self.is_playing: return
        
        # Calculate total steps: visits + path drawing?
        # Actually path is usually a subset of visits or we just highlight it at the end?
        # Let's animate visits, then animate path trace.
        
        total_steps = len(self.visits_log) + len(self.solution_path)
        
        if self.sim_index < total_steps:
            self.do_step(1, is_auto=True)
            delay = int(self.sim_speed * 1000)
            self.animation_job = self.root.after(delay, self.animate_loop)
        else:
            self.is_playing = False
            self.btn_play.config(text="▶")

    def do_step(self, direction, is_auto=False):
        # direction +1 or -1
        # If moving forward: draw current step
        # If moving back: undraw current step
        
        # Modes:
        # Phase 1: Visits (0 to len(visits)-1)
        # Phase 2: Path (len(visits) to len(visits)+len(path)-1)
        
        num_visits = len(self.visits_log)
        num_path = len(self.solution_path)
        total = num_visits + num_path
        
        target = self.sim_index + direction
        if target < 0 or target > total:
            return # Boundary
        
        # Logic for FORWARD (Drawing)
        if direction > 0:
            step = self.sim_index # The index processing NOW
            
            if step < num_visits:
                # Draw Visit
                c, r = self.visits_log[step]
                # Avoid overwriting Start/Goal visuals if possible, or overlay?
                # Usually we color visited nodes.
                tag = f"cell_{c}_{r}"
                # Don't color over start/goal/walls
                if (c, r) != self.map_data["start"] and (c, r) not in self.map_data["goals"]:
                     self.canvas.itemconfig(tag, fill=THEME["color_visit"])
            else:
                # Draw Path
                p_idx = step - num_visits
                c, r = self.solution_path[p_idx]
                tag = f"cell_{c}_{r}"
                if (c, r) != self.map_data["start"] and (c, r) not in self.map_data["goals"]:
                    self.canvas.itemconfig(tag, fill=THEME["color_path"])

        # Logic for BACKWARD (Undrawing)
        else:
             step = self.sim_index - 1 # The index to UNDO
             
             if step >= num_visits:
                 # Undo Path -> revert to Visit color
                 p_idx = step - num_visits
                 c, r = self.solution_path[p_idx]
                 tag = f"cell_{c}_{r}"
                 if (c, r) != self.map_data["start"] and (c, r) not in self.map_data["goals"]:
                    self.canvas.itemconfig(tag, fill=THEME["color_visit"])
             else:
                 # Undo Visit -> revert to Empty
                 c, r = self.visits_log[step]
                 tag = f"cell_{c}_{r}"
                 if (c, r) != self.map_data["start"] and (c, r) not in self.map_data["goals"]:
                    self.canvas.itemconfig(tag, fill=THEME["color_empty"])

        self.sim_index = target

if __name__ == "__main__":
    root = tk.Tk()
    app = LabyrinthGUI(root)
    root.mainloop()
