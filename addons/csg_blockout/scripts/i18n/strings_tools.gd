@tool
extends RefCounted
## Strings for the P1 viewport tools (grid, nudge, draw, openings, face drag, array).

const STRINGS: Dictionary = {
	"NUDGE_ACTION": {
		"zh": "微调位置", "en": "Nudge", "ja": "位置を微調整", "ko": "위치 미세 조정",
		"es": "Desplazar", "pt": "Ajustar posição", "ru": "Сдвинуть",
	},
	"ROTATE_ACTION": {
		"zh": "旋转", "en": "Rotate", "ja": "回転", "ko": "회전",
		"es": "Rotar", "pt": "Girar", "ru": "Повернуть",
	},
	"DROP_ACTION": {
		"zh": "落到下方表面", "en": "Drop to Surface", "ja": "下の面に落とす", "ko": "아래 표면에 내려놓기",
		"es": "Bajar a la superficie", "pt": "Soltar na superfície", "ru": "Опустить на поверхность",
	},
	"SNAP_SELECTION_TO_GRID": {
		"zh": "选中对齐到栅格", "en": "Snap Selection to Grid", "ja": "選択をグリッドに揃える", "ko": "선택 항목을 그리드에 맞추기",
		"es": "Ajustar selección a la cuadrícula", "pt": "Alinhar seleção à grade", "ru": "Выровнять выделение по сетке",
	},
	"GRID_SIZE_TOOLTIP": {
		"zh": "栅格尺寸（[ 和 ] 切换）", "en": "Grid size ([ and ] to change)", "ja": "グリッドサイズ（[ と ] で変更）", "ko": "그리드 크기 ([ 및 ]로 변경)",
		"es": "Tamaño de cuadrícula ([ y ] para cambiar)", "pt": "Tamanho da grade ([ e ] para mudar)", "ru": "Шаг сетки ([ и ] для изменения)",
	},
	"SNAP": {
		"zh": "吸附", "en": "Snap", "ja": "スナップ", "ko": "스냅",
		"es": "Ajuste", "pt": "Encaixe", "ru": "Привязка",
	},
	"SNAP_TOOLTIP": {
		"zh": "CSG Blockout 工具按栅格吸附（拖动时按住 Ctrl 临时反转）", "en": "Snap CSG Blockout tools to the grid (hold Ctrl while dragging to invert)",
		"ja": "CSG Blockout のツールをグリッドにスナップ（ドラッグ中 Ctrl で一時反転）", "ko": "CSG Blockout 도구를 그리드에 스냅 (드래그 중 Ctrl로 일시 반전)",
		"es": "Ajustar las herramientas de CSG Blockout a la cuadrícula (mantén Ctrl al arrastrar para invertir)", "pt": "Encaixar as ferramentas do CSG Blockout na grade (segure Ctrl ao arrastar para inverter)",
		"ru": "Привязка инструментов CSG Blockout к сетке (удерживайте Ctrl при перетаскивании, чтобы инвертировать)",
	},
	"ROOM": {
		"zh": "房间", "en": "Room", "ja": "部屋", "ko": "방",
		"es": "Habitación", "pt": "Sala", "ru": "Комната",
	},
	"PUSH_FACE_ACTION": {
		"zh": "推拉面", "en": "Push/Pull Face", "ja": "面を押し出し/引き込み", "ko": "면 밀기/당기기",
		"es": "Empujar/tirar cara", "pt": "Empurrar/puxar face", "ru": "Сдвинуть грань",
	},
	"ARRAY_ACTION": {
		"zh": "沿轴复制", "en": "Duplicate Along Axis", "ja": "軸に沿って複製", "ko": "축을 따라 복제",
		"es": "Duplicar a lo largo de un eje", "pt": "Duplicar ao longo do eixo", "ru": "Дублировать вдоль оси",
	},
	"ARRAY_LABEL": {
		"zh": "×%d · 间距 %s m · 轴 %s", "en": "×%d · step %s m · axis %s", "ja": "×%d · 間隔 %s m · 軸 %s", "ko": "×%d · 간격 %s m · 축 %s",
		"es": "×%d · paso %s m · eje %s", "pt": "×%d · passo %s m · eixo %s", "ru": "×%d · шаг %s м · ось %s",
	},
	"DOOR": {
		"zh": "门", "en": "Door", "ja": "ドア", "ko": "문",
		"es": "Puerta", "pt": "Porta", "ru": "Дверь",
	},
	"WINDOW": {
		"zh": "窗", "en": "Window", "ja": "窓", "ko": "창문",
		"es": "Ventana", "pt": "Janela", "ru": "Окно",
	},
	"FRAME": {
		"zh": "带框", "en": "Frame", "ja": "枠あり", "ko": "틀 포함",
		"es": "Marco", "pt": "Moldura", "ru": "Рама",
	},
	"MORE_MENU": {
		"zh": "更多", "en": "More", "ja": "その他", "ko": "더 보기",
		"es": "Más", "pt": "Mais", "ru": "Ещё",
	},
	"MORE_ACTIONS_TOOLTIP": {
		"zh": "更多 CSG Blockout 操作", "en": "More CSG Blockout actions", "ja": "その他の CSG Blockout 操作", "ko": "기타 CSG Blockout 작업",
		"es": "Más acciones de CSG Blockout", "pt": "Mais ações do CSG Blockout", "ru": "Другие действия CSG Blockout",
	},
	"TOOL_BOX": {
		"zh": "方块", "en": "Box", "ja": "ボックス", "ko": "박스",
		"es": "Caja", "pt": "Caixa", "ru": "Блок",
	},
	"TOOL_ROOM": {
		"zh": "房间", "en": "Room", "ja": "部屋", "ko": "방",
		"es": "Habitación", "pt": "Sala", "ru": "Комната",
	},
	"TOOL_CUT": {
		"zh": "切割", "en": "Cut", "ja": "切り抜き", "ko": "자르기",
		"es": "Cortar", "pt": "Cortar", "ru": "Вырез",
	},
	"DRAW_BOX_TOOLTIP": {
		"zh": "方块：在表面或地面上拖出底面，松开即完成（双击按钮可连续使用）", "en": "Box: drag out a base on a surface or the ground and release (double-click to keep the tool on)", "ja": "ボックス：面か地面で底面をドラッグして離すだけ（ダブルクリックで連続使用）", "ko": "박스: 표면이나 바닥에서 밑면을 드래그하고 놓기 (더블 클릭하면 계속 사용)",
		"es": "Caja: arrastra una base sobre una superficie o el suelo y suelta (doble clic para mantener la herramienta)", "pt": "Caixa: arraste uma base sobre uma superfície ou o chão e solte (clique duplo para manter a ferramenta)", "ru": "Блок: протяните основание по поверхности или земле и отпустите (двойной щелчок — оставить инструмент)",
	},
	"DRAW_ROOM_TOOLTIP": {
		"zh": "房间：拖出地面，松开即生成一个独立的空心房间；层高、墙厚等见项目设置 addons/csg_blockout/room（双击按钮可连续使用）", "en": "Room: drag out the floor and release to make a hollow room of its own; height, wall thickness and more in Project Settings > addons/csg_blockout/room (double-click to keep the tool on)", "ja": "部屋：床をドラッグして離すと独立した中空の部屋に。高さや壁厚はプロジェクト設定 addons/csg_blockout/room（ダブルクリックで連続使用）", "ko": "방: 바닥을 드래그하고 놓으면 독립된 빈 방이 생깁니다. 높이·벽 두께는 프로젝트 설정 addons/csg_blockout/room (더블 클릭하면 계속 사용)",
		"es": "Habitación: arrastra el suelo y suelta para crear una habitación hueca propia; altura, grosor de muros y más en Ajustes del proyecto > addons/csg_blockout/room (doble clic para mantener la herramienta)", "pt": "Sala: arraste o piso e solte para criar uma sala oca própria; altura, espessura das paredes e mais em Configurações do projeto > addons/csg_blockout/room (clique duplo para manter a ferramenta)", "ru": "Комната: протяните пол и отпустите — получится отдельная полая комната; высота, толщина стен и прочее в настройках проекта addons/csg_blockout/room (двойной щелчок — оставить инструмент)",
	},
	"DRAW_CUT_TOOLTIP": {
		"zh": "切割：在物体表面拖出切口，松开即贯穿切开（双击按钮可连续使用）", "en": "Cut: drag out an opening on an object's surface and release to cut through it (double-click to keep the tool on)", "ja": "切り抜き：オブジェクトの面で開口をドラッグして離すと貫通して切り抜く（ダブルクリックで連続使用）", "ko": "자르기: 물체 표면에서 구멍을 드래그하고 놓으면 관통해서 잘라냅니다 (더블 클릭하면 계속 사용)",
		"es": "Cortar: arrastra una abertura sobre la superficie de un objeto y suelta para atravesarlo (doble clic para mantener la herramienta)", "pt": "Cortar: arraste uma abertura na superfície de um objeto e solte para atravessá-lo (clique duplo para manter a ferramenta)", "ru": "Вырез: протяните проём по поверхности объекта и отпустите, чтобы прорезать его насквозь (двойной щелчок — оставить инструмент)",
	},
	"OPENING_DOOR_TOOLTIP": {
		"zh": "门：点击墙面开出门洞，自动落地、按墙厚切穿（双击按钮可连续使用）", "en": "Door: click a wall to cut a doorway, dropped to the floor and cut through the wall (double-click to keep the tool on)", "ja": "ドア：壁をクリックして床まで壁厚を貫通する開口を切る（ダブルクリックで連続使用）", "ko": "문: 벽을 클릭해 바닥까지 벽을 관통하는 문 구멍을 뚫기 (더블 클릭하면 계속 사용)",
		"es": "Puerta: haz clic en un muro para abrir un hueco a ras de suelo que lo atraviesa (doble clic para mantener la herramienta)", "pt": "Porta: clique numa parede para abrir um vão no nível do chão que a atravessa (clique duplo para manter a ferramenta)", "ru": "Дверь: щёлкните по стене, чтобы вырезать проём от пола насквозь (двойной щелчок — оставить инструмент)",
	},
	"OPENING_WINDOW_TOOLTIP": {
		"zh": "窗：点击墙面按窗台高度开出窗洞（双击按钮可连续使用）", "en": "Window: click a wall to cut a window at sill height (double-click to keep the tool on)", "ja": "窓：壁をクリックして窓台の高さに開口を切る（ダブルクリックで連続使用）", "ko": "창문: 벽을 클릭해 창턱 높이에 창 구멍 뚫기 (더블 클릭하면 계속 사용)",
		"es": "Ventana: haz clic en un muro para abrir una ventana a la altura del alféizar (doble clic para mantener la herramienta)", "pt": "Janela: clique numa parede para abrir uma janela na altura do peitoril (clique duplo para manter a ferramenta)", "ru": "Окно: щёлкните по стене, чтобы вырезать окно на высоте подоконника (двойной щелчок — оставить инструмент)",
	},
	"STEP_DRAW_BOX": {
		"zh": "在表面上拖出底面", "en": "Drag out the base on a surface", "ja": "面の上で底面をドラッグ", "ko": "표면 위에서 밑면을 드래그",
		"es": "Arrastra la base sobre una superficie", "pt": "Arraste a base sobre uma superfície", "ru": "Протяните основание по поверхности",
	},
	"STEP_DRAW_ROOM": {
		"zh": "拖出房间的地面", "en": "Drag out the room's floor", "ja": "部屋の床をドラッグ", "ko": "방의 바닥을 드래그",
		"es": "Arrastra el suelo de la habitación", "pt": "Arraste o piso da sala", "ru": "Протяните пол комнаты",
	},
	"STEP_DRAW_CUT": {
		"zh": "在物体表面上拖出切口", "en": "Drag out the cut on a surface", "ja": "面の上で切り抜きをドラッグ", "ko": "표면 위에서 잘라낼 영역을 드래그",
		"es": "Arrastra el corte sobre una superficie", "pt": "Arraste o corte sobre uma superfície", "ru": "Протяните вырез по поверхности",
	},
	"STEP_RELEASE": {
		"zh": "松开即完成", "en": "Release to finish", "ja": "離すと完成", "ko": "놓으면 완성",
		"es": "Suelta para terminar", "pt": "Solte para concluir", "ru": "Отпустите, чтобы закончить",
	},
	"STEP_CUT_NEEDS_SURFACE": {
		"zh": "切口要从物体表面开始拖", "en": "Start the cut on an object's surface", "ja": "切り抜きはオブジェクトの面から始めてください", "ko": "자르기는 물체 표면에서 시작하세요",
		"es": "Empieza el corte sobre la superficie de un objeto", "pt": "Comece o corte na superfície de um objeto", "ru": "Начните вырез на поверхности объекта",
	},
	"STEP_OPENING_HOVER": {
		"zh": "移到墙面上", "en": "Move onto a wall", "ja": "壁の上へ", "ko": "벽 위로 이동",
		"es": "Pasa sobre un muro", "pt": "Passe sobre uma parede", "ru": "Наведите на стену",
	},
	"STEP_DOOR_CLICK": {
		"zh": "点击开门", "en": "Click to cut the door", "ja": "クリックでドアを開ける", "ko": "클릭해서 문 뚫기",
		"es": "Haz clic para abrir la puerta", "pt": "Clique para abrir a porta", "ru": "Щёлкните, чтобы вырезать дверь",
	},
	"STEP_WINDOW_CLICK": {
		"zh": "点击开窗", "en": "Click to cut the window", "ja": "クリックで窓を開ける", "ko": "클릭해서 창문 뚫기",
		"es": "Haz clic para abrir la ventana", "pt": "Clique para abrir a janela", "ru": "Щёлкните, чтобы вырезать окно",
	},
	"STEP_ARRAY_AXIS": {
		"zh": "沿 X、Y 或 Z 移动鼠标", "en": "Move the mouse along X, Y or Z", "ja": "X・Y・Z に沿ってマウスを動かす", "ko": "X, Y, Z 방향으로 마우스 이동",
		"es": "Mueve el ratón a lo largo de X, Y o Z", "pt": "Mova o mouse ao longo de X, Y ou Z", "ru": "Ведите мышь вдоль X, Y или Z",
	},
	"STEP_ARRAY_CLICK": {
		"zh": "点击生成 %d 份", "en": "Click to make %d copies", "ja": "クリックで %d 個作成", "ko": "클릭해서 %d개 만들기",
		"es": "Haz clic para crear %d copias", "pt": "Clique para criar %d cópias", "ru": "Щёлкните, чтобы создать копий: %d",
	},
	"TAG_SEPARATE": {
		"zh": "单独放置", "en": "Separate", "ja": "単独で配置", "ko": "따로 배치",
		"es": "Aparte", "pt": "Separado", "ru": "Отдельно",
	},
	"TAG_LOCK_AXIS": {
		"zh": "锁轴", "en": "Lock axis", "ja": "軸固定", "ko": "축 고정",
		"es": "Fijar eje", "pt": "Travar eixo", "ru": "Ось",
	},
	"TAG_GAP": {
		"zh": "间距 %s m", "en": "Gap %s m", "ja": "間隔 %s m", "ko": "간격 %s m",
		"es": "Separación %s m", "pt": "Espaço %s m", "ru": "Зазор %s м",
	},
	"TAG_LOCKED": {
		"zh": "连续使用", "en": "Repeat", "ja": "連続", "ko": "연속",
		"es": "Repetir", "pt": "Repetir", "ru": "Повтор",
	},
	"KEY_EXIT": {
		"zh": "退出", "en": "Exit", "ja": "終了", "ko": "종료",
		"es": "Salir", "pt": "Sair", "ru": "Выход",
	},
	"RESIZE_ACTION": {
		"zh": "调整尺寸", "en": "Resize", "ja": "サイズを変更", "ko": "크기 조정",
		"es": "Cambiar tamaño", "pt": "Redimensionar", "ru": "Изменить размер",
	},
	"STATUS_TREE_SELECTED": {
		"zh": "已选中整棵树：%s", "en": "Selected the whole tree: %s", "ja": "ツリー全体を選択：%s", "ko": "트리 전체 선택: %s",
		"es": "Árbol completo seleccionado: %s", "pt": "Árvore inteira selecionada: %s", "ru": "Выбрано всё дерево: %s",
	},
	"PIE_PLAY": {
		"zh": "试玩", "en": "Play", "ja": "プレイ", "ko": "플레이",
		"es": "Jugar", "pt": "Jogar", "ru": "Играть",
	},
	"PIE_SHAPES": {
		"zh": "形状", "en": "Shapes", "ja": "形状", "ko": "도형",
		"es": "Formas", "pt": "Formas", "ru": "Фигуры",
	},
	"PIE_SNAP": {
		"zh": "对齐栅格", "en": "Snap to Grid", "ja": "グリッドに揃える", "ko": "그리드에 맞추기",
		"es": "Ajustar a la cuadrícula", "pt": "Alinhar à grade", "ru": "По сетке",
	},
	"PIE_TO_UNION": {
		"zh": "改为并集", "en": "Make Union", "ja": "和集合にする", "ko": "합집합으로",
		"es": "Convertir en unión", "pt": "Tornar união", "ru": "Сделать объединением",
	},
	"PIE_TO_SUBTRACT": {
		"zh": "改为差集", "en": "Make Subtraction", "ja": "差集合にする", "ko": "차집합으로",
		"es": "Convertir en sustracción", "pt": "Tornar subtração", "ru": "Сделать вычитанием",
	},
	"PIE_TO_INTERSECT": {
		"zh": "改为交集", "en": "Make Intersection", "ja": "積集合にする", "ko": "교집합으로",
		"es": "Convertir en intersección", "pt": "Tornar interseção", "ru": "Сделать пересечением",
	},
	"REASON_SELECT_CSG": {
		"zh": "先选中 CSG 物体", "en": "Select a CSG shape first", "ja": "先に CSG を選択してください", "ko": "먼저 CSG를 선택하세요",
		"es": "Selecciona primero una forma CSG", "pt": "Selecione primeiro uma forma CSG", "ru": "Сначала выберите CSG-фигуру",
	},
	"REASON_SELECT_ANY": {
		"zh": "先选中物体", "en": "Select something first", "ja": "先にオブジェクトを選択してください", "ko": "먼저 대상을 선택하세요",
		"es": "Selecciona algo primero", "pt": "Selecione algo primeiro", "ru": "Сначала выберите объект",
	},
	"STATUS_OP_CHANGED": {
		"zh": "已把 %d 个改为%s", "en": "Changed %d to %s", "ja": "%d 個を%sに変更しました", "ko": "%d개를 %s(으)로 변경했습니다",
		"es": "%d cambiados a %s", "pt": "%d alterados para %s", "ru": "Изменено: %d → %s",
	},
	"SHAPE_BUTTON_HINT": {
		"zh": "点击创建：有选中时放在它旁边，否则放在视图中央。Shift+A 饼菜单可直接放到光标下", "en": "Click to create: next to the selection, or in the middle of the view. The Shift+A pie menu puts it under the cursor.", "ja": "クリックで作成：選択の隣、選択がなければビューの中央に。Shift+A のパイメニューならカーソル位置に置けます", "ko": "클릭하여 생성: 선택한 대상 옆에, 선택이 없으면 뷰 중앙에 놓입니다. Shift+A 파이 메뉴로 커서 위치에 놓을 수 있습니다",
		"es": "Clic para crear: junto a la selección o en el centro de la vista. El menú circular Shift+A lo coloca bajo el cursor.", "pt": "Clique para criar: ao lado da seleção ou no centro da vista. O menu radial Shift+A coloca sob o cursor.", "ru": "Щелчок — создать: рядом с выделением или в центре вида. Круговое меню Shift+A ставит под курсор.",
	},
	"OP_UNION_TOOLTIP": {
		"zh": "改为并集：选中的 CSG 与前面的形状合并", "en": "Union: the selected CSG shapes add to the shapes before them", "ja": "和集合：選択した CSG を前の形状に足す", "ko": "합집합: 선택한 CSG를 앞의 도형에 더합니다",
		"es": "Unión: las formas CSG seleccionadas se suman a las anteriores", "pt": "União: as formas CSG selecionadas somam-se às anteriores", "ru": "Объединение: выбранные CSG-фигуры добавляются к предыдущим",
	},
	"OP_SUBTRACT_TOOLTIP": {
		"zh": "改为差集：用选中的 CSG 从前面的形状里挖掉", "en": "Subtraction: the selected CSG shapes carve into the shapes before them", "ja": "差集合：選択した CSG で前の形状をくり抜く", "ko": "차집합: 선택한 CSG로 앞의 도형을 파냅니다",
		"es": "Sustracción: las formas CSG seleccionadas vacían las anteriores", "pt": "Subtração: as formas CSG selecionadas escavam as anteriores", "ru": "Вычитание: выбранные CSG-фигуры вырезаются из предыдущих",
	},
	"OP_INTERSECT_TOOLTIP": {
		"zh": "改为交集：只保留与前面形状重叠的部分", "en": "Intersection: keep only where the selected CSG shapes overlap the shapes before them", "ja": "積集合：前の形状と重なる部分だけを残す", "ko": "교집합: 앞의 도형과 겹치는 부분만 남깁니다",
		"es": "Intersección: conserva solo la parte que se solapa con las formas anteriores", "pt": "Interseção: mantém só a parte que se sobrepõe às formas anteriores", "ru": "Пересечение: остаётся только часть, общая с предыдущими фигурами",
	},
	"STATUS_MATERIAL_APPLIED": {
		"zh": "已给 %d 个物体换上材质", "en": "Material applied to %d", "ja": "%d 個にマテリアルを適用しました", "ko": "%d개에 머티리얼을 적용했습니다",
		"es": "Material aplicado a %d", "pt": "Material aplicado a %d", "ru": "Материал применён: %d",
	},
	"LANGUAGE_MENU": {
		"zh": "语言", "en": "Language", "ja": "言語", "ko": "언어",
		"es": "Idioma", "pt": "Idioma", "ru": "Язык",
	},
	"LANGUAGE_AUTO": {
		"zh": "自动（跟随编辑器）", "en": "Auto (editor language)", "ja": "自動（エディターの言語）", "ko": "자동 (에디터 언어)",
		"es": "Automático (idioma del editor)", "pt": "Automático (idioma do editor)", "ru": "Авто (язык редактора)",
	},
	"SHORTCUTS_MENU": {
		"zh": "快捷键速查…", "en": "Shortcuts…", "ja": "ショートカット一覧…", "ko": "단축키 목록…",
		"es": "Atajos…", "pt": "Atalhos…", "ru": "Горячие клавиши…",
	},
	"CHEAT_TITLE": {
		"zh": "CSG Blockout 快捷键", "en": "CSG Blockout Shortcuts", "ja": "CSG Blockout のショートカット", "ko": "CSG Blockout 단축키",
		"es": "Atajos de CSG Blockout", "pt": "Atalhos do CSG Blockout", "ru": "Горячие клавиши CSG Blockout",
	},
	"CHEAT_PIE": {
		"zh": "在光标处打开饼菜单：工具、形状、试玩", "en": "Pie menu at the cursor: tools, shapes, play", "ja": "カーソル位置にパイメニュー：ツール、形状、プレイ", "ko": "커서 위치에 파이 메뉴: 도구, 도형, 플레이",
		"es": "Menú circular en el cursor: herramientas, formas, jugar", "pt": "Menu radial no cursor: ferramentas, formas, jogar", "ru": "Круговое меню у курсора: инструменты, фигуры, игра",
	},
	"CHEAT_ESC": {
		"zh": "退出当前工具 / 关闭饼菜单（右键单击也能退出工具）", "en": "Leave the current tool / close the pie menu (a right-click also leaves the tool)", "ja": "ツールを終了 / パイメニューを閉じる（右クリックでもツールを終了）", "ko": "현재 도구 종료 / 파이 메뉴 닫기 (오른쪽 클릭으로도 도구 종료)",
		"es": "Salir de la herramienta / cerrar el menú circular (el clic derecho también sale)", "pt": "Sair da ferramenta / fechar o menu radial (o clique direito também sai)", "ru": "Выйти из инструмента / закрыть круговое меню (правый щелчок тоже выходит)",
	},
	"CHEAT_KEY_DOUBLE_CLICK_TOOL": {
		"zh": "双击工具按钮", "en": "Double-click a tool button", "ja": "ツールボタンをダブルクリック", "ko": "도구 버튼 더블 클릭",
		"es": "Doble clic en una herramienta", "pt": "Clique duplo numa ferramenta", "ru": "Двойной щелчок по инструменту",
	},
	"CHEAT_LOCK": {
		"zh": "保持工具开启，连续使用", "en": "Keep the tool on for several uses", "ja": "ツールを続けて使う", "ko": "도구를 계속 켜 두고 연속 사용",
		"es": "Mantener la herramienta para varios usos", "pt": "Manter a ferramenta para vários usos", "ru": "Оставить инструмент включённым",
	},
	"CHEAT_SEPARATE": {
		"zh": "画方块时按住：作为独立物体，不并入下方的树", "en": "Hold while drawing a box: a separate object instead of joining the tree below", "ja": "ボックス描画中に押す：下のツリーに入れず独立したオブジェクトに", "ko": "박스를 그릴 때 누르기: 아래 트리에 합치지 않고 별도 오브젝트로",
		"es": "Mantén al dibujar una caja: objeto aparte en lugar de unirse al árbol de debajo", "pt": "Segure ao desenhar uma caixa: objeto separado em vez de juntar à árvore abaixo", "ru": "Удерживайте при рисовании блока: отдельный объект вместо присоединения к дереву",
	},
	"CHEAT_FRAME": {
		"zh": "门 / 窗工具中：切换是否带框", "en": "Door / window tool: toggle the frame", "ja": "ドア / 窓ツール：枠の有無を切り替え", "ko": "문 / 창문 도구: 틀 켜기/끄기",
		"es": "Herramienta puerta / ventana: activar el marco", "pt": "Ferramenta porta / janela: alternar a moldura", "ru": "Дверь / окно: включить или выключить раму",
	},
	"CHEAT_GRID": {
		"zh": "栅格变小 / 变大", "en": "Smaller / bigger grid", "ja": "グリッドを小さく / 大きく", "ko": "그리드 작게 / 크게",
		"es": "Cuadrícula más pequeña / grande", "pt": "Grade menor / maior", "ru": "Шаг сетки меньше / больше",
	},
	"CHEAT_NUDGE": {
		"zh": "按栅格水平移动选中物体（相对视角）", "en": "Move the selection one grid step horizontally (relative to the view)", "ja": "選択をグリッド単位で水平移動（視点基準）", "ko": "선택 항목을 그리드 단위로 수평 이동 (뷰 기준)",
		"es": "Mover la selección un paso de cuadrícula en horizontal (según la vista)", "pt": "Mover a seleção um passo de grade na horizontal (conforme a vista)", "ru": "Сдвинуть выделение на шаг сетки по горизонтали (относительно вида)",
	},
	"CHEAT_NUDGE_VERTICAL": {
		"zh": "按栅格上下移动", "en": "Move one grid step up / down", "ja": "グリッド単位で上下に移動", "ko": "그리드 단위로 위 / 아래 이동",
		"es": "Subir / bajar un paso de cuadrícula", "pt": "Subir / descer um passo de grade", "ru": "Сдвинуть на шаг сетки вверх / вниз",
	},
	"CHEAT_ROTATE": {
		"zh": "绕竖直轴旋转 15°（按住 Shift 为 90°）", "en": "Rotate 15° around the vertical axis (90° with Shift)", "ja": "鉛直軸まわりに 15° 回転（Shift で 90°）", "ko": "수직축 기준 15° 회전 (Shift는 90°)",
		"es": "Girar 15° sobre el eje vertical (90° con Mayús)", "pt": "Girar 15° no eixo vertical (90° com Shift)", "ru": "Поворот на 15° вокруг вертикали (с Shift — 90°)",
	},
	"CHEAT_KEY_DRAG_ARROW": {
		"zh": "拖动面上的箭头", "en": "Drag a face arrow", "ja": "面の矢印をドラッグ", "ko": "면의 화살표 드래그",
		"es": "Arrastrar una flecha de cara", "pt": "Arrastar uma seta de face", "ru": "Тянуть стрелку грани",
	},
	"CHEAT_PUSH": {
		"zh": "推拉这个面，对面不动", "en": "Push or pull that face; the opposite face stays", "ja": "その面を押し出し・引き込み（反対の面は固定）", "ko": "그 면을 밀거나 당기기 (반대쪽 면은 고정)",
		"es": "Empujar o tirar de esa cara; la opuesta no se mueve", "pt": "Empurrar ou puxar a face; a oposta fica parada", "ru": "Сдвинуть эту грань; противоположная остаётся на месте",
	},
	"CHEAT_KEY_CLICK_LABEL": {
		"zh": "点击尺寸标注", "en": "Click a dimension label", "ja": "寸法ラベルをクリック", "ko": "치수 라벨 클릭",
		"es": "Clic en una cota", "pt": "Clique numa cota", "ru": "Щелчок по размеру",
	},
	"CHEAT_TYPE_SIZE": {
		"zh": "输入精确尺寸（回车确认）", "en": "Type an exact size (Enter to apply)", "ja": "正確なサイズを入力（Enter で確定）", "ko": "정확한 크기 입력 (Enter로 적용)",
		"es": "Escribir un tamaño exacto (Intro para aplicar)", "pt": "Digitar um tamanho exato (Enter para aplicar)", "ru": "Ввести точный размер (Enter — применить)",
	},
	"CHEAT_KEY_DOUBLE_CLICK_SHAPE": {
		"zh": "双击物体", "en": "Double-click a shape", "ja": "形状をダブルクリック", "ko": "도형 더블 클릭",
		"es": "Doble clic en una forma", "pt": "Clique duplo numa forma", "ru": "Двойной щелчок по фигуре",
	},
	"CHEAT_TREE": {
		"zh": "选中它所在的整棵 CSG 树", "en": "Select its whole CSG tree", "ja": "その CSG ツリー全体を選択", "ko": "해당 CSG 트리 전체 선택",
		"es": "Seleccionar todo su árbol CSG", "pt": "Selecionar toda a árvore CSG", "ru": "Выбрать всё его CSG-дерево",
	},
	"CHEAT_REBIND_NOTE": {
		"zh": "键位可在 编辑器设置 → 快捷键 → csg_blockout 中修改", "en": "Rebind keys in Editor Settings → Shortcuts → csg_blockout", "ja": "キーは エディター設定 → ショートカット → csg_blockout で変更できます", "ko": "키는 에디터 설정 → 단축키 → csg_blockout에서 바꿀 수 있습니다",
		"es": "Cambia las teclas en Configuración del editor → Atajos → csg_blockout", "pt": "Altere as teclas em Configurações do editor → Atalhos → csg_blockout", "ru": "Клавиши меняются в Настройки редактора → Горячие клавиши → csg_blockout",
	},
	"ACTION_NEXT": {
		"zh": "下一个 ›", "en": "Next ›", "ja": "次へ ›", "ko": "다음 ›",
		"es": "Siguiente ›", "pt": "Próximo ›", "ru": "Далее ›",
	},
	"ACTION_OPEN_FOLDER": {
		"zh": "打开文件夹 ›", "en": "Open folder ›", "ja": "フォルダーを開く ›", "ko": "폴더 열기 ›",
		"es": "Abrir carpeta ›", "pt": "Abrir pasta ›", "ru": "Открыть папку ›",
	},
	"ACTION_SHOW_IN_FILESYSTEM": {
		"zh": "在文件系统中显示 ›", "en": "Show in FileSystem ›", "ja": "ファイルシステムで表示 ›", "ko": "파일시스템에서 보기 ›",
		"es": "Mostrar en Sistema de archivos ›", "pt": "Mostrar no Sistema de arquivos ›", "ru": "Показать в файловой системе ›",
	},
	"STATUS_CHECK_ISSUE": {
		"zh": "问题 %d/%d：%s — %s", "en": "Issue %d/%d: %s — %s", "ja": "問題 %d/%d：%s — %s", "ko": "문제 %d/%d: %s — %s",
		"es": "Problema %d/%d: %s — %s", "pt": "Problema %d/%d: %s — %s", "ru": "Проблема %d/%d: %s — %s",
	},
	"STATUS_FROZEN": {
		"zh": "已冻结 %d 棵 CSG 树", "en": "Froze %d CSG tree(s)", "ja": "CSG ツリーを %d 個フリーズしました", "ko": "CSG 트리 %d개를 고정했습니다",
		"es": "%d árbol(es) CSG congelado(s)", "pt": "%d árvore(s) CSG congelada(s)", "ru": "Заморожено CSG-деревьев: %d",
	},
	"STATUS_UNFROZEN": {
		"zh": "已解冻 %d 个，恢复为可编辑的 CSG", "en": "Unfroze %d: editable CSG again", "ja": "%d 個のフリーズを解除し、編集可能な CSG に戻しました", "ko": "%d개 고정 해제: 다시 편집 가능한 CSG",
		"es": "%d descongelado(s): CSG editable de nuevo", "pt": "%d descongelado(s): CSG editável de novo", "ru": "Разморожено: %d, снова редактируемый CSG",
	},
}
