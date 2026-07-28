from __future__ import annotations

import json
from dataclasses import asdict
from typing import Any

from starlette.requests import Request
from starlette.responses import HTMLResponse, JSONResponse
from starlette.routing import Route

from agentsoul_core.hybrid import HybridStore
from agentsoul_core.knowledge import KnowledgeStore
from agentsoul_core.store import MemoryStore


def _home():
    return MemoryStore().initialise()


def _hybrid() -> HybridStore:
    return HybridStore(_home())


def _knowledge() -> KnowledgeStore:
    return KnowledgeStore(_home())


async def _json(request: Request) -> dict[str, Any]:
    try:
        payload = await request.json()
    except json.JSONDecodeError as exc:
        raise ValueError("request body must be valid JSON") from exc
    if not isinstance(payload, dict):
        raise ValueError("request body must be a JSON object")
    return payload


def _ok(data: Any = None, status: int = 200) -> JSONResponse:
    return JSONResponse({"ok": True, "data": data}, status_code=status)


def _error(exc: Exception) -> JSONResponse:
    status = 404 if isinstance(exc, FileNotFoundError) else 400
    return JSONResponse({"ok": False, "error": str(exc)}, status_code=status)


async def api_snapshot(_: Request) -> JSONResponse:
    hybrid = _hybrid()
    return _ok({
        "notes": [asdict(item) for item in hybrid.list_notes()],
        "entities": [asdict(item) for item in hybrid.list_entities()],
        "links": hybrid.list_links(),
        "knowledge": [item.to_dict() for item in _knowledge().list_items()],
    })


async def api_search(request: Request) -> JSONResponse:
    query = request.query_params.get("q", "").strip()
    if not query:
        return _ok({"notes": [], "entities": [], "knowledge": []})
    hybrid_results = _hybrid().search(query, limit=100)
    query_lower = query.lower()
    knowledge = [
        item.to_dict() for item in _knowledge().list_items()
        if query_lower in item.title.lower() or query_lower in item.summary.lower()
    ][:100]
    return _ok({**hybrid_results, "knowledge": knowledge})


async def api_notes(request: Request) -> JSONResponse:
    try:
        payload = await _json(request)
        note = _hybrid().add_note(
            str(payload.get("title", "")),
            str(payload.get("body", "")),
            source=payload.get("source"),
            metadata=payload.get("metadata") or {},
        )
        return _ok(asdict(note), 201)
    except Exception as exc:
        return _error(exc)


async def api_note_item(request: Request) -> JSONResponse:
    note_id = request.path_params["note_id"]
    try:
        if request.method == "DELETE":
            return _ok({"deleted": _hybrid().delete_note(note_id)})
        payload = await _json(request)
        note = _hybrid().update_note(
            note_id,
            title=str(payload.get("title", "")),
            body=str(payload.get("body", "")),
            source=payload.get("source"),
            metadata=payload.get("metadata") or {},
        )
        return _ok(asdict(note))
    except Exception as exc:
        return _error(exc)


async def api_entities(request: Request) -> JSONResponse:
    try:
        payload = await _json(request)
        entity = _hybrid().upsert_entity(
            str(payload.get("entity_type", "")),
            str(payload.get("name", "")),
            payload.get("attributes") or {},
        )
        return _ok(asdict(entity), 201)
    except Exception as exc:
        return _error(exc)


async def api_entity_item(request: Request) -> JSONResponse:
    entity_id = request.path_params["entity_id"]
    try:
        if request.method == "DELETE":
            return _ok({"deleted": _hybrid().delete_entity(entity_id)})
        payload = await _json(request)
        entity = _hybrid().update_entity(
            entity_id,
            entity_type=str(payload.get("entity_type", "")),
            name=str(payload.get("name", "")),
            attributes=payload.get("attributes") or {},
        )
        return _ok(asdict(entity))
    except Exception as exc:
        return _error(exc)


async def api_links(request: Request) -> JSONResponse:
    try:
        payload = await _json(request)
        link = _hybrid().link(
            str(payload.get("subject_id", "")),
            str(payload.get("predicate", "")),
            str(payload.get("object_id", "")),
            payload.get("metadata") or {},
        )
        return _ok(link, 201)
    except Exception as exc:
        return _error(exc)


async def api_link_item(request: Request) -> JSONResponse:
    return _ok({"deleted": _hybrid().delete_link(request.path_params["link_id"])})


async def api_knowledge(request: Request) -> JSONResponse:
    try:
        payload = await _json(request)
        kind = str(payload.get("kind", ""))
        if kind not in {"case", "pattern", "principle"}:
            raise ValueError("kind must be case, pattern, or principle")
        item = _knowledge().capture(
            kind=kind,  # type: ignore[arg-type]
            title=str(payload.get("title", "")),
            summary=str(payload.get("summary", "")),
            confidence=int(payload.get("confidence", 2)),
            anchors=payload.get("anchors") or {},
            evidence=payload.get("evidence") or [],
        )
        return _ok(item.to_dict(), 201)
    except Exception as exc:
        return _error(exc)


async def api_knowledge_item(request: Request) -> JSONResponse:
    return _ok({"deleted": _knowledge().delete(request.path_params["knowledge_id"])})


INDEX = r'''<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AgentSoul Memory</title><style>
:root{color-scheme:light dark;--bg:#f5f6f8;--card:#fff;--text:#17191c;--muted:#68707a;--line:#d9dde3;--accent:#405cf5;--danger:#b42318}
@media(prefers-color-scheme:dark){:root{--bg:#111318;--card:#1a1e25;--text:#f5f6f8;--muted:#a3aab4;--line:#313741;--accent:#8da2ff;--danger:#ff8d85}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.45 system-ui,sans-serif}
header{padding:20px;display:flex;gap:14px;align-items:center;flex-wrap:wrap;border-bottom:1px solid var(--line);background:var(--card)}
main{max-width:1180px;margin:auto;padding:20px}.grow{flex:1}.muted{color:var(--muted)}input,textarea,select,button{font:inherit}
input,textarea,select{width:100%;padding:10px;border:1px solid var(--line);border-radius:10px;background:var(--card);color:var(--text)}textarea{min-height:90px}
button{padding:9px 13px;border:0;border-radius:10px;background:var(--accent);color:white;cursor:pointer}button.secondary{background:transparent;color:var(--text);border:1px solid var(--line)}button.danger{background:transparent;color:var(--danger);border:1px solid var(--danger)}
nav{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:18px}.tab.active{background:var(--accent);color:white}.tab{background:var(--card);color:var(--text);border:1px solid var(--line)}
.panel{display:none}.panel.active{display:block}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:14px}.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:15px}.row{display:flex;gap:10px;align-items:center;flex-wrap:wrap}.stack{display:grid;gap:10px}.item{border-top:1px solid var(--line);padding:12px 0}.item:first-child{border-top:0}.badge{display:inline-block;padding:2px 8px;border-radius:999px;background:color-mix(in srgb,var(--accent) 15%,transparent);color:var(--accent);font-size:12px}.actions{display:flex;gap:7px;margin-top:9px}.wide{grid-column:1/-1}pre{white-space:pre-wrap;word-break:break-word}.status{min-height:22px}
</style></head><body>
<header><div><strong>AgentSoul</strong><div class="muted">Гибридная память</div></div><div class="grow"></div><input id="token" style="max-width:320px" type="password" placeholder="Bearer token"><button id="load">Загрузить</button></header>
<main><div class="row" style="margin-bottom:16px"><input id="search" placeholder="Поиск по памяти"><button id="searchBtn">Найти</button><button class="secondary" id="reset">Сбросить</button></div><div id="status" class="status muted"></div>
<nav><button class="tab active" data-tab="notes">Заметки</button><button class="tab" data-tab="entities">Сущности</button><button class="tab" data-tab="links">Связи</button><button class="tab" data-tab="knowledge">Знания</button></nav>
<section id="notes" class="panel active"><div class="grid"><form id="noteForm" class="card stack"><strong>Новая заметка</strong><input name="title" placeholder="Заголовок" required><textarea name="body" placeholder="Текст" required></textarea><input name="source" placeholder="Источник"><button>Сохранить</button></form><div class="card wide"><strong>Заметки</strong><div id="noteList"></div></div></div></section>
<section id="entities" class="panel"><div class="grid"><form id="entityForm" class="card stack"><strong>Новая сущность</strong><input name="entity_type" placeholder="Тип: company, project, document" required><input name="name" placeholder="Название" required><textarea name="attributes" placeholder='Атрибуты JSON, например {"status":"active"}'></textarea><button>Сохранить</button></form><div class="card wide"><strong>Сущности</strong><div id="entityList"></div></div></div></section>
<section id="links" class="panel"><div class="grid"><form id="linkForm" class="card stack"><strong>Новая связь</strong><select name="subject_id" id="subject"></select><input name="predicate" placeholder="Связь: uses, owns, related_to" required><select name="object_id" id="object"></select><button>Связать</button></form><div class="card wide"><strong>Связи</strong><div id="linkList"></div></div></div></section>
<section id="knowledge" class="panel"><div class="grid"><form id="knowledgeForm" class="card stack"><strong>Проверенное знание</strong><select name="kind"><option>case</option><option>pattern</option><option>principle</option></select><input name="title" placeholder="Заголовок" required><textarea name="summary" placeholder="Краткий проверенный вывод" required></textarea><select name="confidence"><option>1</option><option selected>2</option><option>3</option><option>4</option><option>5</option></select><button>Сохранить</button></form><div class="card wide"><strong>Знания</strong><div id="knowledgeList"></div></div></div></section>
</main><script>
let snapshot={notes:[],entities:[],links:[],knowledge:[]};const $=s=>document.querySelector(s);const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function headers(){const t=$('#token').value.trim();return {'content-type':'application/json',...(t?{authorization:'Bearer '+t}:{})}}
async function api(path,opts={}){const r=await fetch(path,{...opts,headers:{...headers(),...(opts.headers||{})}});const j=await r.json();if(!r.ok||!j.ok)throw new Error(j.error||'Ошибка запроса');return j.data}
function status(t,e=false){$('#status').textContent=t;$('#status').style.color=e?'var(--danger)':''}
function parseJson(v){if(!v.trim())return {};try{return JSON.parse(v)}catch{throw new Error('Некорректный JSON')}}
function render(data=snapshot){const names=Object.fromEntries(snapshot.entities.map(e=>[e.entity_id,e.name]));$('#noteList').innerHTML=(data.notes||[]).map(n=>`<div class="item"><b>${esc(n.title)}</b><div>${esc(n.body)}</div><small class="muted">${esc(n.source||'без источника')}</small><div class="actions"><button class="danger" data-del-note="${n.note_id}">Удалить</button></div></div>`).join('')||'<p class="muted">Пусто</p>';$('#entityList').innerHTML=(data.entities||[]).map(e=>`<div class="item"><span class="badge">${esc(e.entity_type)}</span> <b>${esc(e.name)}</b><pre class="muted">${esc(JSON.stringify(e.attributes,null,2))}</pre><div class="actions"><button class="danger" data-del-entity="${e.entity_id}">Удалить</button></div></div>`).join('')||'<p class="muted">Пусто</p>';$('#linkList').innerHTML=(data.links||[]).map(l=>`<div class="item"><b>${esc(names[l.subject_id]||l.subject_id)}</b> → ${esc(l.predicate)} → <b>${esc(names[l.object_id]||l.object_id)}</b><div class="actions"><button class="danger" data-del-link="${l.link_id}">Удалить</button></div></div>`).join('')||'<p class="muted">Пусто</p>';$('#knowledgeList').innerHTML=(data.knowledge||[]).map(k=>`<div class="item"><span class="badge">${esc(k.kind)}</span> <b>${esc(k.title)}</b><div>${esc(k.summary)}</div><small class="muted">Уверенность ${k.confidence}/5 · ${esc(k.status)}</small><div class="actions"><button class="danger" data-del-knowledge="${k.knowledge_id}">Удалить</button></div></div>`).join('')||'<p class="muted">Пусто</p>';const opts=snapshot.entities.map(e=>`<option value="${e.entity_id}">${esc(e.name)} (${esc(e.entity_type)})</option>`).join('');$('#subject').innerHTML=opts;$('#object').innerHTML=opts}
async function load(){try{status('Загрузка…');snapshot=await api('/api/snapshot');render();status(`Загружено: ${snapshot.notes.length} заметок, ${snapshot.entities.length} сущностей, ${snapshot.knowledge.length} знаний`)}catch(e){status(e.message,true)}}
$('#load').addEventListener('click',load);$('#reset').addEventListener('click',()=>{render();$('#search').value=''});$('#searchBtn').addEventListener('click',async()=>{try{const q=$('#search').value.trim();if(!q)return render();const r=await api('/api/search?q='+encodeURIComponent(q));render({...snapshot,...r,links:snapshot.links})}catch(e){status(e.message,true)}});
document.querySelectorAll('.tab').forEach(b=>b.addEventListener('click',()=>{document.querySelectorAll('.tab,.panel').forEach(x=>x.classList.remove('active'));b.classList.add('active');$('#'+b.dataset.tab).classList.add('active')}));
$('#noteForm').addEventListener('submit',async e=>{e.preventDefault();const f=new FormData(e.target);try{await api('/api/notes',{method:'POST',body:JSON.stringify({title:f.get('title'),body:f.get('body'),source:f.get('source')||null})});e.target.reset();load()}catch(x){status(x.message,true)}});
$('#entityForm').addEventListener('submit',async e=>{e.preventDefault();const f=new FormData(e.target);try{await api('/api/entities',{method:'POST',body:JSON.stringify({entity_type:f.get('entity_type'),name:f.get('name'),attributes:parseJson(String(f.get('attributes')||''))})});e.target.reset();load()}catch(x){status(x.message,true)}});
$('#linkForm').addEventListener('submit',async e=>{e.preventDefault();const f=new FormData(e.target);try{await api('/api/links',{method:'POST',body:JSON.stringify(Object.fromEntries(f))});e.target.reset();load()}catch(x){status(x.message,true)}});
$('#knowledgeForm').addEventListener('submit',async e=>{e.preventDefault();const f=new FormData(e.target);try{await api('/api/knowledge',{method:'POST',body:JSON.stringify({kind:f.get('kind'),title:f.get('title'),summary:f.get('summary'),confidence:Number(f.get('confidence'))})});e.target.reset();load()}catch(x){status(x.message,true)}});
document.addEventListener('click',async e=>{const b=e.target.closest('button');if(!b)return;const pairs=[['delNote','/api/notes/'],['delEntity','/api/entities/'],['delLink','/api/links/'],['delKnowledge','/api/knowledge/']];for(const [key,path] of pairs){const attr='data-'+key.replace(/[A-Z]/g,m=>'-'+m.toLowerCase());if(b.hasAttribute(attr)){if(confirm('Удалить запись?')){try{await api(path+b.getAttribute(attr),{method:'DELETE'});load()}catch(x){status(x.message,true)}}}}});
</script></body></html>'''


async def ui(_: Request) -> HTMLResponse:
    return HTMLResponse(INDEX)


routes = [
    Route("/ui", ui, methods=["GET"]),
    Route("/api/snapshot", api_snapshot, methods=["GET"]),
    Route("/api/search", api_search, methods=["GET"]),
    Route("/api/notes", api_notes, methods=["POST"]),
    Route("/api/notes/{note_id}", api_note_item, methods=["PUT", "DELETE"]),
    Route("/api/entities", api_entities, methods=["POST"]),
    Route("/api/entities/{entity_id}", api_entity_item, methods=["PUT", "DELETE"]),
    Route("/api/links", api_links, methods=["POST"]),
    Route("/api/links/{link_id}", api_link_item, methods=["DELETE"]),
    Route("/api/knowledge", api_knowledge, methods=["POST"]),
    Route("/api/knowledge/{knowledge_id}", api_knowledge_item, methods=["DELETE"]),
]
