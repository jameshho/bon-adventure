from pathlib import Path
import re,json,collections,sys
D=Path(__file__).resolve().parents[3]
errors=[];warnings=[];stats=collections.Counter()
for f in D.rglob('*'):
 if f.is_file() and f.suffix in ('.gd','.tscn','.godot'):
  t=f.read_text()
  for p in re.findall(r'res://([A-Za-z0-9_./-]+)',t):
   if not (D/p).exists() and not (D/p.rstrip('.')).exists(): errors.append((str(f.relative_to(D)),f'missing resource {p}'))
  if f.suffix=='.tscn':
   roots=re.findall(r'\[node\s+name="([^"]+)"(?:\s+type="[^"]+")?\s+parent="([^"]+)"',t)
   names={}
   for name,parent in roots:
    if (parent,name) in names:errors.append((f.name,f'duplicate node {parent}/{name}'))
    names[(parent,name)]=1
   for name,parent in roots:
    if parent!='.' and not any(name2==parent.split('/')[-1] for name2,_ in roots) and not (parent in ['/','']):
     errors.append((f.name,f'missing possible parent {parent} for {name}'))
   subs=re.findall(r'\[sub_resource type="([^"]+)" id="([^"]+)"\]',t)
   exts=re.findall(r'\[ext_resource type="([^"]+)" path="([^"]+)" id="([^"]+)"\]',t)
   for ref in re.findall(r'SubResource\("([^"]+)"\)',t):
    if ref not in [i for _,i in subs]:errors.append((f.name,f'unknown subresource {ref}'))
   for ref in re.findall(r'ExtResource\("([^"]+)"\)',t):
    if ref not in [i for _,_,i in exts]:errors.append((f.name,f'unknown extresource {ref}'))
   info=re.search(r'\[gd_scene load_steps=(\d+) format=3\]',t)
   if info and int(info.group(1))!=1+len(subs)+len(exts):errors.append((f.name,'incorrect load_steps'))
   stats['saved_scene_files']+=1
   stats['saved_node_entries']+=len(re.findall(r'\[node ',t))
   stats['shared_subresources']+=len(subs)
  if f.suffix=='.gd':
   if re.search(r'for\s+\w+\s*,\s*\w+\s+in\b',t): warnings.append((f.name,'unsupported Python-style tuple loop'))
   stats['scripts']+=1
sys.path.insert(0,str(D/'tools'))
import word_data  # data/words.json is the only word source
_words=word_data.load()
v=word_data.vocabulary(_words);v.update({a:t for a,t in _words['aliases'].items()});v.update({k:k for k in _words.get('removed_with_objects',[])})
cats=_words['categories']
for f in (D/'scenes').rglob('*.tscn'):
 t=f.read_text()
 for key in re.findall(r'metadata/word_key = "([^"]+)"',t):
  if key and key not in v:errors.append((f.name,f'vocab missing: {key}'))
  stats['interactive_root_keys']+=1
print('STATS',dict(stats))
print('DICTIONARY',len(v),'categories',len(cats))
print('ERRORS',len(errors))
for e in errors[:55]:print('ERROR',e)
print('WARNINGS',len(warnings))
for w in warnings[:20]:print('WARN',w)
if errors: sys.exit(1)
