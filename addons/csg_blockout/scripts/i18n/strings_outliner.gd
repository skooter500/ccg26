@tool
extends RefCounted
## Strings for the blockout outliner dock.

const STRINGS: Dictionary = {
	"OUTLINER_TITLE": {
		"zh": "白盒", "en": "Blockout", "ja": "ブロックアウト", "ko": "블록아웃",
		"es": "Blockout", "pt": "Blockout", "ru": "Блокаут",
	},
	"OUTLINER_TAB": {
		"zh": "大纲", "en": "Outliner", "ja": "アウトライナー", "ko": "아웃라이너",
		"es": "Esquema", "pt": "Estrutura", "ru": "Структура",
	},
	"OUTLINER_FILTER": {
		"zh": "筛选节点", "en": "Filter nodes", "ja": "ノードを絞り込み", "ko": "노드 필터",
		"es": "Filtrar nodos", "pt": "Filtrar nós", "ru": "Фильтр узлов",
	},
	"OUTLINER_GROUP": {
		"zh": "编组：把选中的节点放进新组合器", "en": "Group: put the selected nodes into a new combiner",
		"ja": "グループ化：選択ノードを新しいコンバイナーに入れる", "ko": "그룹: 선택한 노드를 새 컴바이너에 넣기",
		"es": "Agrupar: mete los nodos seleccionados en un combinador nuevo", "pt": "Agrupar: coloca os nós selecionados num novo combinador",
		"ru": "Сгруппировать: поместить выбранные узлы в новый комбинатор",
	},
	"OUTLINER_UNGROUP": {
		"zh": "解组：把组合器的子节点移到上一级并删除组合器", "en": "Ungroup: move the combiner's children up a level and remove it",
		"ja": "グループ解除：子を一つ上に移しコンバイナーを削除", "ko": "그룹 해제: 자식을 한 단계 위로 옮기고 컴바이너 삭제",
		"es": "Desagrupar: sube los hijos un nivel y elimina el combinador", "pt": "Desagrupar: sobe os filhos um nível e remove o combinador",
		"ru": "Разгруппировать: поднять дочерние узлы на уровень выше и удалить комбинатор",
	},
	"OUTLINER_RENAME": {
		"zh": "语义重命名：选中节点（未选中时为整个场景）改为 Wall_Corridor_01 这样的名字", "en": "Semantic rename: name the selection (or the whole scene) like Wall_Corridor_01",
		"ja": "意味的リネーム：選択（未選択ならシーン全体）を Wall_Corridor_01 のように命名", "ko": "의미 기반 이름 변경: 선택(없으면 씬 전체)을 Wall_Corridor_01 형식으로",
		"es": "Renombrado semántico: nombra la selección (o toda la escena) como Wall_Corridor_01", "pt": "Renomeação semântica: nomeia a seleção (ou a cena inteira) como Wall_Corridor_01",
		"ru": "Смысловое переименование: выделение (или вся сцена) получает имена вида Wall_Corridor_01",
	},
	"RENAME_SEMANTIC_ACTION": {
		"zh": "语义重命名", "en": "Semantic Rename", "ja": "意味的リネーム", "ko": "의미 기반 이름 변경",
		"es": "Renombrado semántico", "pt": "Renomeação semântica", "ru": "Смысловое переименование",
	},
	"OUTLINER_STATUS": {
		"zh": "%d 棵 CSG 树 · %d 个节点", "en": "%d CSG trees · %d nodes", "ja": "CSG ツリー %d · ノード %d", "ko": "CSG 트리 %d개 · 노드 %d개",
		"es": "%d árboles CSG · %d nodos", "pt": "%d árvores CSG · %d nós", "ru": "Деревьев CSG: %d · узлов: %d",
	},
	"OUTLINER_FROZEN_TOOLTIP": {
		"zh": "已冻结：网格 + 碰撞，可解冻回 CSG", "en": "Frozen: mesh + collision, can be unfrozen back to CSG",
		"ja": "フリーズ済み：メッシュ＋コリジョン、CSG に戻せる", "ko": "고정됨: 메시 + 콜리전, CSG로 되돌릴 수 있음",
		"es": "Congelado: malla + colisión, se puede volver a CSG", "pt": "Congelado: malha + colisão, pode voltar a CSG",
		"ru": "Заморожено: меш + коллизия, можно вернуть в CSG",
	},
	"OUTLINER_VISIBLE": {
		"zh": "显示/隐藏", "en": "Show/Hide", "ja": "表示/非表示", "ko": "표시/숨기기",
		"es": "Mostrar/ocultar", "pt": "Mostrar/ocultar", "ru": "Показать/скрыть",
	},
	"OUTLINER_SOLO": {
		"zh": "隔离显示（只在编辑器里隐藏其他白盒，不修改场景）", "en": "Solo (hides the other blockout in the editor only; the scene is not changed)",
		"ja": "ソロ表示（他のブロックアウトをエディターでのみ隠す。シーンは変更しない）", "ko": "단독 표시 (다른 블록아웃을 에디터에서만 숨김, 씬은 변경 안 됨)",
		"es": "Solo (oculta el resto del blockout solo en el editor; la escena no cambia)", "pt": "Solo (oculta o restante do blockout só no editor; a cena não muda)",
		"ru": "Соло (скрывает остальной блокаут только в редакторе; сцена не меняется)",
	},
	"OUTLINER_LOCK": {
		"zh": "锁定（视口中不可选中）", "en": "Lock (can't be selected in the viewport)", "ja": "ロック（ビューポートで選択不可）", "ko": "잠금 (뷰포트에서 선택 불가)",
		"es": "Bloquear (no se puede seleccionar en el viewport)", "pt": "Travar (não pode ser selecionado na viewport)", "ru": "Заблокировать (нельзя выбрать во вьюпорте)",
	},
}
