@tool
extends RefCounted
## Strings for reversible bake (freeze / unfreeze) and the bake pipeline.

const STRINGS: Dictionary = {
	"FREEZE": {
		"zh": "冻结", "en": "Freeze", "ja": "フリーズ", "ko": "고정",
		"es": "Congelar", "pt": "Congelar", "ru": "Заморозить",
	},
	"UNFREEZE": {
		"zh": "解冻", "en": "Unfreeze", "ja": "フリーズ解除", "ko": "고정 해제",
		"es": "Descongelar", "pt": "Descongelar", "ru": "Разморозить",
	},
	"FREEZE_ACTION": {
		"zh": "冻结 CSG", "en": "Freeze CSG", "ja": "CSG をフリーズ", "ko": "CSG 고정",
		"es": "Congelar CSG", "pt": "Congelar CSG", "ru": "Заморозить CSG",
	},
	"UNFREEZE_ACTION": {
		"zh": "解冻 CSG", "en": "Unfreeze CSG", "ja": "CSG のフリーズを解除", "ko": "CSG 고정 해제",
		"es": "Descongelar CSG", "pt": "Descongelar CSG", "ru": "Разморозить CSG",
	},
	"FREEZE_TOOLTIP": {
		"zh": "冻结：把选中的 CSG 树烘焙成网格 + 碰撞，原 CSG 保存在节点里，可随时解冻",
		"en": "Freeze: bake the selected CSG trees into a mesh + collision; the CSG is kept inside the node so you can unfreeze any time",
		"ja": "フリーズ：選択した CSG ツリーをメッシュとコリジョンに焼き込む。CSG はノード内に保存され、いつでも解除できる",
		"ko": "고정: 선택한 CSG 트리를 메시 + 콜리전으로 굽기. CSG는 노드 안에 보관되어 언제든 해제 가능",
		"es": "Congelar: hornea los árboles CSG seleccionados en malla + colisión; el CSG se guarda en el nodo para descongelarlo cuando quieras",
		"pt": "Congelar: converte as árvores CSG selecionadas em malha + colisão; o CSG fica guardado no nó para descongelar quando quiser",
		"ru": "Заморозить: запечь выбранные деревья CSG в меш и коллизию; CSG хранится в узле, разморозить можно в любой момент",
	},
	"UNFREEZE_TOOLTIP": {
		"zh": "解冻：把冻结的网格还原成可编辑的 CSG，节点名和对节点的定制会在下次冻结时保留",
		"en": "Unfreeze: turn the frozen mesh back into editable CSG; the node name and your customizations come back on the next freeze",
		"ja": "フリーズ解除：焼き込んだメッシュを編集可能な CSG に戻す。ノード名とカスタマイズは次のフリーズで復元",
		"ko": "고정 해제: 고정된 메시를 편집 가능한 CSG로 되돌림. 노드 이름과 사용자 설정은 다음 고정 때 유지",
		"es": "Descongelar: vuelve a convertir la malla congelada en CSG editable; el nombre y tus ajustes del nodo se conservan al volver a congelar",
		"pt": "Descongelar: transforma a malha congelada de volta em CSG editável; o nome e seus ajustes do nó voltam no próximo congelamento",
		"ru": "Разморозить: вернуть замороженный меш в редактируемый CSG; имя узла и ваши настройки сохранятся при следующей заморозке",
	},
	"WARN_FREEZE_SCENE_ROOT": {
		"zh": "不能冻结场景根节点，请先把 CSG 放进一个子组合器", "en": "The scene root can't be frozen; put the CSG under a child combiner first",
		"ja": "シーンのルートはフリーズできません。先に CSG を子のコンバイナーに入れてください", "ko": "씬 루트는 고정할 수 없습니다. 먼저 CSG를 하위 컴바이너에 넣으세요",
		"es": "La raíz de la escena no se puede congelar; coloca el CSG dentro de un combinador hijo", "pt": "A raiz da cena não pode ser congelada; coloque o CSG num combinador filho",
		"ru": "Корень сцены нельзя заморозить; сначала поместите CSG в дочерний комбинатор",
	},
	"WARN_FREEZE_EMPTY": {
		"zh": "%s 没有可烘焙的几何体，已跳过", "en": "%s has no geometry to bake; skipped",
		"ja": "%s には焼き込むジオメトリがないためスキップしました", "ko": "%s에는 구울 지오메트리가 없어 건너뜁니다",
		"es": "%s no tiene geometría que hornear; se omite", "pt": "%s não tem geometria para converter; ignorado",
		"ru": "У %s нет геометрии для запекания; пропущено",
	},
	"WARN_FREEZE_REFERENCES": {
		"zh": "冻结 %s 后，这些 NodePath 会指向不存在的节点：%s", "en": "After freezing %s, these NodePaths point to nodes that no longer exist: %s",
		"ja": "%s をフリーズすると、次の NodePath が存在しないノードを指します：%s", "ko": "%s 고정 후 다음 NodePath는 존재하지 않는 노드를 가리킵니다: %s",
		"es": "Tras congelar %s, estos NodePath apuntan a nodos que ya no existen: %s", "pt": "Depois de congelar %s, estes NodePath apontam para nós que não existem mais: %s",
		"ru": "После заморозки %s эти NodePath указывают на несуществующие узлы: %s",
	},
	"FROZEN_PANEL_TITLE": {
		"zh": "❄ 冻结的白盒", "en": "❄ Frozen blockout", "ja": "❄ フリーズ済みブロックアウト", "ko": "❄ 고정된 블록아웃",
		"es": "❄ Blockout congelado", "pt": "❄ Blockout congelado", "ru": "❄ Замороженный блокаут",
	},
	"BAKE_COLLISION": {
		"zh": "碰撞", "en": "Collision", "ja": "コリジョン", "ko": "콜리전",
		"es": "Colisión", "pt": "Colisão", "ru": "Коллизия",
	},
	"COLLISION_AUTO": {
		"zh": "自动（沿用 CSG 的 use_collision）", "en": "Auto (follow the CSG's use_collision)", "ja": "自動（CSG の use_collision に従う）", "ko": "자동 (CSG의 use_collision 따름)",
		"es": "Automática (según use_collision del CSG)", "pt": "Automática (segue use_collision do CSG)", "ru": "Авто (по use_collision у CSG)",
	},
	"COLLISION_NONE": {
		"zh": "无", "en": "None", "ja": "なし", "ko": "없음",
		"es": "Ninguna", "pt": "Nenhuma", "ru": "Нет",
	},
	"COLLISION_TRIMESH": {
		"zh": "三角网格（精确）", "en": "Trimesh (exact)", "ja": "三角メッシュ（正確）", "ko": "삼각 메시 (정확)",
		"es": "Trimesh (exacta)", "pt": "Trimesh (exata)", "ru": "Тримеш (точная)",
	},
	"COLLISION_PRIMITIVES": {
		"zh": "逐图元原生形状（最快，仅纯并集）", "en": "Per-primitive shapes (fastest, union only)", "ja": "プリミティブごとの形状（最速、和のみ）", "ko": "도형별 기본 형태 (가장 빠름, 합집합만)",
		"es": "Formas por primitiva (más rápida, solo unión)", "pt": "Formas por primitiva (mais rápida, só união)", "ru": "Формы по примитивам (быстрее всего, только объединение)",
	},
	"COLLISION_CONVEX": {
		"zh": "整体凸包", "en": "Single convex hull", "ja": "全体の凸包", "ko": "전체 볼록 껍질",
		"es": "Envolvente convexa única", "pt": "Envoltória convexa única", "ru": "Одна выпуклая оболочка",
	},
	"BAKE_UV2": {
		"zh": "生成光照贴图 UV2", "en": "Lightmap UV2", "ja": "ライトマップ UV2", "ko": "라이트맵 UV2",
		"es": "UV2 para lightmap", "pt": "UV2 de lightmap", "ru": "UV2 для лайтмапа",
	},
	"BAKE_TEXEL": {
		"zh": "UV2 纹素尺寸", "en": "UV2 texel size", "ja": "UV2 テクセルサイズ", "ko": "UV2 텍셀 크기",
		"es": "Tamaño de texel UV2", "pt": "Tamanho do texel UV2", "ru": "Размер текселя UV2",
	},
	"BAKE_OCCLUDER": {
		"zh": "生成遮挡体", "en": "Occluder", "ja": "オクルーダー", "ko": "오클루더",
		"es": "Oclusor", "pt": "Oclusor", "ru": "Окклюдер",
	},
	"BAKE_LOD": {
		"zh": "生成 LOD", "en": "LODs", "ja": "LOD を生成", "ko": "LOD 생성",
		"es": "LOD", "pt": "LOD", "ru": "LOD",
	},
	"REBAKE": {
		"zh": "按这些选项重新烘焙", "en": "Rebake With These Options", "ja": "この設定で再ベイク", "ko": "이 설정으로 다시 굽기",
		"es": "Rehornear con estas opciones", "pt": "Refazer com estas opções", "ru": "Перезапечь с этими настройками",
	},
	"REBAKE_ACTION": {
		"zh": "重新烘焙冻结的白盒", "en": "Rebake Frozen Blockout", "ja": "フリーズ済みブロックアウトを再ベイク", "ko": "고정된 블록아웃 다시 굽기",
		"es": "Rehornear blockout congelado", "pt": "Refazer blockout congelado", "ru": "Перезапечь замороженный блокаут",
	},
	"WARN_PRIMITIVE_COLLISION_CUTS": {
		"zh": "树里有差集/交集，逐图元碰撞会堵住切出的洞，已改用三角网格碰撞", "en": "The tree has subtractions/intersections, which per-primitive collision would ignore; used trimesh collision instead",
		"ja": "ツリーに差/積があるため、プリミティブごとのコリジョンでは穴が塞がる。三角メッシュに切り替えました", "ko": "트리에 빼기/교집합이 있어 도형별 콜리전은 구멍을 막습니다. 삼각 메시 콜리전을 사용했습니다",
		"es": "El árbol tiene restas/intersecciones que la colisión por primitiva ignoraría; se usó trimesh", "pt": "A árvore tem subtrações/interseções que a colisão por primitiva ignoraria; usada trimesh",
		"ru": "В дереве есть вычитания/пересечения, которые коллизия по примитивам проигнорирует; использован тримеш",
	},
	"WARN_OCCLUSION_CULLING_OFF": {
		"zh": "已生成遮挡体，但项目设置里没有开启遮挡剔除（渲染 > 遮挡剔除 > 使用遮挡剔除），开启前遮挡体不起作用",
		"en": "Occluder generated, but occlusion culling is off in Project Settings (Rendering > Occlusion Culling > Use Occlusion Culling); it has no effect until you turn it on",
		"ja": "オクルーダーを生成しましたが、プロジェクト設定でオクルージョンカリングが無効です（Rendering > Occlusion Culling > Use Occlusion Culling）。有効にするまで効果はありません",
		"ko": "오클루더를 만들었지만 프로젝트 설정에서 오클루전 컬링이 꺼져 있습니다 (Rendering > Occlusion Culling > Use Occlusion Culling). 켜기 전에는 효과가 없습니다",
		"es": "Se generó el oclusor, pero el occlusion culling está desactivado en la configuración del proyecto (Rendering > Occlusion Culling > Use Occlusion Culling); no tendrá efecto hasta activarlo",
		"pt": "Oclusor gerado, mas o occlusion culling está desligado nas configurações do projeto (Rendering > Occlusion Culling > Use Occlusion Culling); não terá efeito até ligá-lo",
		"ru": "Окклюдер создан, но в настройках проекта выключено отсечение перекрытых объектов (Rendering > Occlusion Culling > Use Occlusion Culling); пока его не включить, окклюдер не работает",
	},
	"MANIFOLD_OK": {
		"zh": "✓ 网格是闭合流形，可以放心用于 CSG", "en": "✓ The mesh is a closed manifold, safe for CSG", "ja": "✓ メッシュは閉じた多様体で、CSG で安全に使えます", "ko": "✓ 메시가 닫힌 매니폴드라 CSG에 안전합니다",
		"es": "✓ La malla es un manifold cerrado, segura para CSG", "pt": "✓ A malha é uma variedade fechada, segura para CSG", "ru": "✓ Меш — замкнутое многообразие, безопасен для CSG",
	},
	"MANIFOLD_BAD": {
		"zh": "⚠ 网格不是闭合流形：%d 条开放边、%d 条被三个以上面共用的边、%d 条朝向相反的边。CSG 可能静默出错（结果为空或缺面）。",
		"en": "⚠ Not a closed manifold: %d open edges, %d edges shared by more than two faces, %d edges with flipped faces. CSG may silently give empty or wrong results.",
		"ja": "⚠ 閉じた多様体ではありません：開いた辺 %d、3 面以上が共有する辺 %d、向きが逆の辺 %d。CSG が黙って空や誤った結果になる可能性があります。",
		"ko": "⚠ 닫힌 매니폴드가 아닙니다: 열린 모서리 %d개, 세 면 이상이 공유하는 모서리 %d개, 방향이 뒤집힌 모서리 %d개. CSG가 조용히 빈 결과나 잘못된 결과를 낼 수 있습니다.",
		"es": "⚠ No es un manifold cerrado: %d aristas abiertas, %d aristas compartidas por más de dos caras, %d aristas con caras invertidas. El CSG puede dar resultados vacíos o erróneos sin avisar.",
		"pt": "⚠ Não é uma variedade fechada: %d arestas abertas, %d arestas compartilhadas por mais de duas faces, %d arestas com faces invertidas. O CSG pode dar resultados vazios ou errados sem aviso.",
		"ru": "⚠ Не замкнутое многообразие: открытых рёбер %d, рёбер с более чем двумя гранями %d, рёбер с перевёрнутыми гранями %d. CSG может молча дать пустой или неверный результат.",
	},
	"MANIFOLD_SKIPPED": {
		"zh": "网格有 %d 个三角形，太大，跳过流形检查", "en": "Mesh has %d triangles; manifold check skipped", "ja": "メッシュが %d 三角形と大きいため多様体チェックを省略", "ko": "메시 삼각형이 %d개로 커서 매니폴드 검사를 건너뜀",
		"es": "La malla tiene %d triángulos; se omite la comprobación", "pt": "A malha tem %d triângulos; verificação ignorada", "ru": "В меше %d треугольников; проверка пропущена",
	},
	"MANIFOLD_SHOW_EDGES": {
		"zh": "在视口中标出问题边", "en": "Show problem edges in the viewport", "ja": "問題の辺をビューポートに表示", "ko": "문제 모서리를 뷰포트에 표시",
		"es": "Mostrar aristas problemáticas en el viewport", "pt": "Mostrar arestas com problema na viewport", "ru": "Показать проблемные рёбра во вьюпорте",
	},
	"EXPORT_MESHLIB": {
		"zh": "导出到 MeshLibrary…", "en": "Export to MeshLibrary…", "ja": "MeshLibrary に書き出し…", "ko": "MeshLibrary로 내보내기…",
		"es": "Exportar a MeshLibrary…", "pt": "Exportar para MeshLibrary…", "ru": "Экспорт в MeshLibrary…",
	},
	"MESHLIB_DIALOG_TITLE": {
		"zh": "导出 %d 个条目到 MeshLibrary（选已有的库会按名字更新条目，其余条目保留）",
		"en": "Export %d items to a MeshLibrary (picking an existing library updates items by name and keeps the rest)",
		"ja": "%d 個のアイテムを MeshLibrary に書き出し（既存のライブラリを選ぶと同名のアイテムを更新し、他は残す）",
		"ko": "%d개 항목을 MeshLibrary로 내보내기 (기존 라이브러리를 고르면 같은 이름의 항목만 갱신하고 나머지는 유지)",
		"es": "Exportar %d elementos a una MeshLibrary (si eliges una existente, se actualizan los elementos con el mismo nombre y se conservan los demás)",
		"pt": "Exportar %d itens para uma MeshLibrary (escolher uma existente atualiza os itens de mesmo nome e mantém o resto)",
		"ru": "Экспорт %d элементов в MeshLibrary (при выборе существующей библиотеки элементы с тем же именем обновляются, остальные сохраняются)",
	},
	"MESHLIB_EXPORTED": {
		"zh": "MeshLibrary：新增 %d 个条目、更新 %d 个 → %s", "en": "MeshLibrary: %d items added, %d updated → %s",
		"ja": "MeshLibrary：%d 個追加、%d 個更新 → %s", "ko": "MeshLibrary: %d개 추가, %d개 갱신 → %s",
		"es": "MeshLibrary: %d elementos añadidos, %d actualizados → %s", "pt": "MeshLibrary: %d itens adicionados, %d atualizados → %s",
		"ru": "MeshLibrary: добавлено %d, обновлено %d → %s",
	},
	"WARN_MESHLIB_NOTHING": {
		"zh": "先选中 CSG、冻结的白盒，或装着它们的父节点", "en": "Select CSG, frozen blockouts, or a node that contains them first",
		"ja": "先に CSG、フリーズ済みブロックアウト、またはそれらを含むノードを選択してください", "ko": "먼저 CSG, 고정된 블록아웃 또는 이를 담은 노드를 선택하세요",
		"es": "Selecciona primero CSG, blockouts congelados o un nodo que los contenga", "pt": "Selecione primeiro CSG, blockouts congelados ou um nó que os contenha",
		"ru": "Сначала выберите CSG, замороженные блокауты или узел, который их содержит",
	},
	"WARN_MESHLIB_NOT_LIBRARY": {
		"zh": "%s 不是 MeshLibrary，未写入", "en": "%s is not a MeshLibrary; nothing was written",
		"ja": "%s は MeshLibrary ではないため書き込みませんでした", "ko": "%s은(는) MeshLibrary가 아니어서 쓰지 않았습니다",
		"es": "%s no es una MeshLibrary; no se escribió nada", "pt": "%s não é uma MeshLibrary; nada foi gravado",
		"ru": "%s не является MeshLibrary; ничего не записано",
	},
	"WARN_MESHLIB_DUPLICATE": {
		"zh": "有多个节点叫 %s，只导出了第一个；条目按名字匹配，请先改名", "en": "Several nodes are named %s; only the first was exported. Items match by name, so rename them first",
		"ja": "%s という名前のノードが複数あるため最初の 1 つだけ書き出しました。アイテムは名前で照合されるので先に名前を変えてください", "ko": "%s 이름의 노드가 여러 개라 첫 번째만 내보냈습니다. 항목은 이름으로 맞추므로 먼저 이름을 바꾸세요",
		"es": "Hay varios nodos llamados %s; solo se exportó el primero. Los elementos se emparejan por nombre: renómbralos antes", "pt": "Há vários nós chamados %s; só o primeiro foi exportado. Os itens são associados pelo nome, então renomeie-os antes",
		"ru": "Несколько узлов называются %s; экспортирован только первый. Элементы сопоставляются по имени — сначала переименуйте их",
	},
	"GLTF_SECTION": {
		"zh": "glTF 往返（去 Blender 等工具精修）", "en": "glTF round trip (refine in Blender etc.)", "ja": "glTF ラウンドトリップ（Blender などで仕上げ）", "ko": "glTF 왕복 (Blender 등에서 다듬기)",
		"es": "Ida y vuelta glTF (refinar en Blender, etc.)", "pt": "Ida e volta glTF (refinar no Blender etc.)", "ru": "Обмен через glTF (доработка в Blender и др.)",
	},
	"GLTF_EXPORT": {
		"zh": "导出 .glb", "en": "Export .glb", "ja": ".glb を書き出し", "ko": ".glb 내보내기",
		"es": "Exportar .glb", "pt": "Exportar .glb", "ru": "Экспорт .glb",
	},
	"GLTF_APPLY": {
		"zh": "用精修网格替换", "en": "Use Refined Mesh", "ja": "仕上げたメッシュを使う", "ko": "다듬은 메시 사용",
		"es": "Usar malla refinada", "pt": "Usar malha refinada", "ru": "Взять доработанный меш",
	},
	"GLTF_APPLY_ACTION": {
		"zh": "替换为精修网格", "en": "Use Refined Mesh", "ja": "仕上げたメッシュに置き換え", "ko": "다듬은 메시로 교체",
		"es": "Usar malla refinada", "pt": "Usar malha refinada", "ru": "Заменить доработанным мешем",
	},
	"GLTF_EXPORT_MENU": {
		"zh": "把冻结的白盒导出为 .glb（去精修）", "en": "Export Frozen Blockout as .glb (for Refinement)", "ja": "フリーズ済みブロックアウトを .glb に書き出し（仕上げ用）", "ko": "고정된 블록아웃을 .glb로 내보내기 (다듬기용)",
		"es": "Exportar blockout congelado como .glb (para refinar)", "pt": "Exportar blockout congelado como .glb (para refinar)", "ru": "Экспорт замороженного блокаута в .glb (для доработки)",
	},
	"GLTF_APPLY_MENU": {
		"zh": "用 .glb 里的精修网格替换", "en": "Use Refined Meshes from .glb", "ja": ".glb の仕上げたメッシュを使う", "ko": ".glb의 다듬은 메시 사용",
		"es": "Usar mallas refinadas del .glb", "pt": "Usar malhas refinadas do .glb", "ru": "Взять доработанные меши из .glb",
	},
	"GLTF_SHOW_FILE": {
		"zh": "在文件管理器中显示 .glb", "en": "Show the .glb in the file manager", "ja": ".glb をファイルマネージャーで表示", "ko": "파일 관리자에서 .glb 보기",
		"es": "Mostrar el .glb en el gestor de archivos", "pt": "Mostrar o .glb no gerenciador de arquivos", "ru": "Показать .glb в файловом менеджере",
	},
	"GLTF_EXPORTED": {
		"zh": "已导出 %d 个 .glb 到 %s", "en": "Exported %d .glb file(s) to %s", "ja": "%d 個の .glb を %s に書き出しました", "ko": ".glb %d개를 %s에 내보냈습니다",
		"es": "%d archivo(s) .glb exportado(s) a %s", "pt": "%d arquivo(s) .glb exportado(s) para %s", "ru": "Экспортировано .glb: %d → %s",
	},
	"GLTF_OVERWRITE_CONFIRM": {
		"zh": "%s 在上次导出后被改过（多半已经在 Blender 里精修）。仍要用白盒网格覆盖吗？",
		"en": "%s changed after the last export (probably refined in a DCC tool). Overwrite it with the blockout mesh anyway?",
		"ja": "%s は前回の書き出し後に変更されています（おそらく DCC ツールで仕上げ済み）。それでもブロックアウトのメッシュで上書きしますか？",
		"ko": "%s은(는) 마지막 내보내기 이후 바뀌었습니다 (아마 DCC 도구에서 다듬음). 그래도 블록아웃 메시로 덮어쓸까요?",
		"es": "%s cambió después de la última exportación (probablemente se refinó en una herramienta DCC). ¿Sobrescribirlo igualmente con la malla del blockout?",
		"pt": "%s mudou depois da última exportação (provavelmente refinado numa ferramenta DCC). Sobrescrever mesmo assim com a malha do blockout?",
		"ru": "%s изменён после последнего экспорта (вероятно, доработан в DCC). Всё равно перезаписать мешем блокаута?",
	},
	"GLTF_UNFREEZE_CONFIRM": {
		"zh": "%s 正在使用精修网格。解冻会回到 CSG，并从场景里移除精修网格（.glb 文件保留）。继续吗？",
		"en": "%s uses a refined mesh. Unfreezing goes back to the CSG and drops the refined mesh from the scene (the .glb file stays). Continue?",
		"ja": "%s は仕上げたメッシュを使っています。フリーズを解除すると CSG に戻り、シーンから仕上げたメッシュが外れます（.glb ファイルは残ります）。続けますか？",
		"ko": "%s은(는) 다듬은 메시를 사용 중입니다. 고정을 해제하면 CSG로 돌아가고 씬에서 다듬은 메시가 빠집니다 (.glb 파일은 남음). 계속할까요?",
		"es": "%s usa una malla refinada. Descongelar vuelve al CSG y quita la malla refinada de la escena (el archivo .glb se conserva). ¿Continuar?",
		"pt": "%s usa uma malha refinada. Descongelar volta ao CSG e remove a malha refinada da cena (o arquivo .glb permanece). Continuar?",
		"ru": "%s использует доработанный меш. Разморозка вернёт CSG и уберёт доработанный меш из сцены (файл .glb останется). Продолжить?",
	},
	"WARN_GLTF_FREEZE_FIRST": {
		"zh": "先选中冻结的白盒：glTF 往返针对冻结节点", "en": "Select frozen blockout first: the glTF round trip works on frozen nodes",
		"ja": "先にフリーズ済みブロックアウトを選択してください。glTF ラウンドトリップはフリーズしたノードが対象です", "ko": "먼저 고정된 블록아웃을 선택하세요. glTF 왕복은 고정된 노드에 적용됩니다",
		"es": "Selecciona primero un blockout congelado: la ida y vuelta glTF trabaja con nodos congelados", "pt": "Selecione primeiro um blockout congelado: a ida e volta glTF funciona com nós congelados",
		"ru": "Сначала выберите замороженный блокаут: обмен через glTF работает с замороженными узлами",
	},
	"WARN_GLTF_SAVE_SCENE": {
		"zh": "先保存场景：.glb 会放在场景文件旁边", "en": "Save the scene first; the .glb files go next to it",
		"ja": "先にシーンを保存してください。.glb はシーンの隣に置かれます", "ko": "먼저 씬을 저장하세요. .glb는 씬 옆에 저장됩니다",
		"es": "Guarda primero la escena; los .glb se guardan junto a ella", "pt": "Salve a cena primeiro; os .glb ficam ao lado dela",
		"ru": "Сначала сохраните сцену: файлы .glb кладутся рядом с ней",
	},
	"WARN_GLTF_NOT_IMPORTED": {
		"zh": "%s 还没有导入，等 Godot 导入完成后再试", "en": "%s isn't imported yet; try again once Godot has finished importing it",
		"ja": "%s はまだインポートされていません。Godot のインポート完了後にもう一度試してください", "ko": "%s이(가) 아직 임포트되지 않았습니다. Godot가 임포트를 마친 뒤 다시 시도하세요",
		"es": "%s aún no se ha importado; inténtalo cuando Godot termine de importarlo", "pt": "%s ainda não foi importado; tente de novo quando o Godot terminar de importá-lo",
		"ru": "%s ещё не импортирован; повторите, когда Godot закончит импорт",
	},
	"WARN_GLTF_NO_MESH": {
		"zh": "%s 里没有找到网格", "en": "No mesh found in %s", "ja": "%s にメッシュが見つかりません", "ko": "%s에서 메시를 찾지 못했습니다",
		"es": "No se encontró ninguna malla en %s", "pt": "Nenhuma malha encontrada em %s", "ru": "В %s не найден меш",
	},
	"GLTF_STATUS_UNSAVED": {
		"zh": "先保存场景，.glb 会导出到场景旁边的 <场景名>_blockout 文件夹。", "en": "Save the scene first; the .glb goes to a <scene>_blockout folder next to it.",
		"ja": "先にシーンを保存してください。.glb はシーンの隣の <シーン名>_blockout フォルダーに書き出されます。", "ko": "먼저 씬을 저장하세요. .glb는 씬 옆의 <씬 이름>_blockout 폴더로 내보내집니다.",
		"es": "Guarda primero la escena; el .glb va a una carpeta <escena>_blockout junto a ella.", "pt": "Salve a cena primeiro; o .glb vai para uma pasta <cena>_blockout ao lado dela.",
		"ru": "Сначала сохраните сцену: .glb попадёт в папку <сцена>_blockout рядом с ней.",
	},
	"GLTF_STATUS_NONE": {
		"zh": "导出 .glb，在 Blender 等工具里精修后覆盖保存，回到这里点\"用精修网格替换\"。CSG 源数据保留，碰撞仍用白盒的。",
		"en": "Export the .glb, refine it in Blender (or any DCC tool) and save over it, then come back and use the refined mesh. The CSG stays inside; collision stays the blockout's.",
		"ja": ".glb を書き出し、Blender などで仕上げて上書き保存したら、ここに戻って仕上げたメッシュを使います。CSG は残り、コリジョンはブロックアウトのままです。",
		"ko": ".glb를 내보내 Blender 등에서 다듬고 덮어 저장한 뒤 여기로 돌아와 다듬은 메시를 사용하세요. CSG는 남고 콜리전은 블록아웃 것을 유지합니다.",
		"es": "Exporta el .glb, refínalo en Blender (u otra herramienta DCC) y guárdalo encima; luego vuelve y usa la malla refinada. El CSG se conserva y la colisión sigue siendo la del blockout.",
		"pt": "Exporte o .glb, refine no Blender (ou outra ferramenta DCC) e salve por cima; depois volte e use a malha refinada. O CSG continua guardado e a colisão continua a do blockout.",
		"ru": "Экспортируйте .glb, доработайте его в Blender (или другом DCC) и сохраните поверх, затем вернитесь и возьмите доработанный меш. CSG сохраняется, коллизия остаётся от блокаута.",
	},
	"GLTF_STATUS_EXPORTED": {
		"zh": "已导出到 %s。在 Blender 里编辑后覆盖保存，Godot 重新导入后这里会提示可以替换。",
		"en": "Exported to %s. Edit it and save over it; once Godot has re-imported it, it shows up here.",
		"ja": "%s に書き出し済み。編集して上書き保存すると、Godot が再インポートした後ここに表示されます。",
		"ko": "%s(으)로 내보냈습니다. 편집 후 덮어 저장하면 Godot가 다시 임포트한 뒤 여기에 표시됩니다.",
		"es": "Exportado a %s. Edítalo y guárdalo encima; cuando Godot lo reimporte, aparecerá aquí.",
		"pt": "Exportado para %s. Edite e salve por cima; quando o Godot reimportar, ele aparece aqui.",
		"ru": "Экспортировано в %s. Отредактируйте и сохраните поверх — после переимпорта в Godot это отобразится здесь.",
	},
	"GLTF_STATUS_READY": {
		"zh": "%s 在 Godot 外被修改过，可以用精修网格替换了。", "en": "%s was changed outside Godot: ready to use the refined mesh.",
		"ja": "%s が Godot の外で変更されました。仕上げたメッシュを使えます。", "ko": "%s이(가) Godot 밖에서 바뀌었습니다. 다듬은 메시를 사용할 수 있습니다.",
		"es": "%s se modificó fuera de Godot: ya puedes usar la malla refinada.", "pt": "%s foi alterado fora do Godot: pronto para usar a malha refinada.",
		"ru": "%s изменён вне Godot: можно взять доработанный меш.",
	},
	"GLTF_STATUS_APPLIED": {
		"zh": "正在使用 %s 的精修网格。重新烘焙或解冻会回到白盒网格。", "en": "Using the refined mesh from %s. Rebaking or unfreezing goes back to the blockout mesh.",
		"ja": "%s の仕上げたメッシュを使用中。再ベイクかフリーズ解除でブロックアウトのメッシュに戻ります。", "ko": "%s의 다듬은 메시를 사용 중입니다. 다시 굽거나 고정을 해제하면 블록아웃 메시로 돌아갑니다.",
		"es": "Usando la malla refinada de %s. Rehornear o descongelar vuelve a la malla del blockout.", "pt": "Usando a malha refinada de %s. Refazer ou descongelar volta à malha do blockout.",
		"ru": "Используется доработанный меш из %s. Перезапекание или разморозка вернут меш блокаута.",
	},
}
