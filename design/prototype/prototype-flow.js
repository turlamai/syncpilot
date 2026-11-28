/* SyncPilot browser prototype: local examples, no daemon control. */
(() => {
 const P=Prototype,{ $, $$, text, esc, link, match, go, modal, status, read, save, copy }=P;
 const file=location.pathname.split('/').pop();
 function add(){modal('添加本地演示文件夹','不会读取目录或建立真实同步。',[{label:'名称',name:'name',required:true},{label:'示例路径',name:'path',required:true,value:'~/Codes/example'}],d=>{const list=read('folders',[]);list.push({...d,size:'—',online:0,total:0,status:'offline'});save('folders',list);if(file==='folders.html'){folders.push(list.at(-1));render();$('#addMenu').open=false}else go('folders.html')},'添加到演示列表')}
 function key(){modal('通过演示密钥加入','只接受 demo-key，不保存或发送输入。',[{label:'演示密钥',name:'key',required:true}],d=>{if(d.key!=='demo-key'){status('请输入 demo-key');return false}status('演示密钥已校验；请添加一个本地示例文件夹')},'验证')}
 if(file==='folders.html'){
   read('folders',[]).forEach(f=>folders.push(f));render();
   document.addEventListener('click',e=>{const b=e.target.closest('[data-action]');if(!b)return;const a=b.dataset.action;if(!['settings','add','key','history','files','pause'].includes(a))return;e.preventDefault();e.stopImmediatePropagation();$('#addMenu').open=false;
     if(a==='settings')go('settings.html');if(a==='add')add();if(a==='key')key();
     if(a==='history')modal('同步历史样例','项目文档 · 接收 48 个文件 · 进行中\n照片库 · 示例同步已完成\n未连接守护进程，不展示实时历史。');
     if(a==='files')modal('共享文件样例','项目文档 / proposal.md\n照片库 / sample.jpg\n条目仅供界面评审，不读取真实文件。');
     if(a==='pause')modal('暂停演示同步？','只改变示例状态，真实守护进程不受影响。',[],()=>{b.setAttribute('aria-label',b.dataset.paused?'暂停同步':'继续同步');b.dataset.paused=b.dataset.paused?'':'1';status(b.dataset.paused?'演示同步已暂停':'演示同步已继续')},'确认');
   },true);
   document.addEventListener('click',e=>{const b=e.target.closest('[data-folder]');if(!b)return;const name=text(b);setTimeout(()=>{const body=$('#dialogBody');if(!body)return;const a=document.createElement('a');a.href='folder-detail.html';a.textContent='查看详情页样例 →';body.append(a)},0)});
 }
 match('button',/添加文件夹/,add);match('button',/粘贴密钥/,key);
 match('button',/打开 SyncPilot 设置/,()=>go('settings.html'));
 P.nav('.foot .item',{偏好设置:'settings.html'});
 if(file==='settings.html'){
   const values=read('settings',{});$$('.entry').forEach((div,i)=>{const input=document.createElement('input');input.className=div.className;input.value=values[i]??text(div);input.type=i===1?'number':'text';input.setAttribute('aria-label',i===1?'本地 API 端口':'设备名');if(i===1){input.min=1024;input.max=65535;input.step=1;input.required=true}div.replaceWith(input)});
   $$('.check').forEach((el,i)=>{if(values['check'+i]!==undefined)el.classList.toggle('off',!values['check'+i]);el.setAttribute('role','checkbox');el.setAttribute('aria-label',text($('.t',el.closest('.row'))));el.setAttribute('aria-checked',!el.classList.contains('off'));link(el,()=>{el.classList.toggle('off');el.setAttribute('aria-checked',!el.classList.contains('off'))})});
   const toast=$('.toast');if(toast)toast.hidden=true;
   match('button',/^保存设置$/,()=>{const entries=$$('.entry');if(!entries.every(x=>x.reportValidity()))return;const v={};entries.forEach((x,i)=>v[i]=x.value);$$('.check').forEach((x,i)=>v['check'+i]=!x.classList.contains('off'));save('settings',v);status('原型偏好已保存 · 未修改守护进程')});
   match('button',/^还原$/,()=>modal('还原演示设置？','仅重置当前浏览器中的原型偏好。',[],()=>{save('settings',{});location.reload()},'还原'));
   match('button',/^浏览/,()=>modal('rslsync 路径','只记录示例路径，不访问或启动文件。',[{label:'路径',name:'path',required:true,value:read('binary','/usr/bin/rslsync')}],d=>{save('binary',d.path);status('示例路径已保存')},'使用'));
   match('button',/^重启/,()=>modal('重启演示守护进程？','不会重启真实进程。',[],()=>status('已完成重启状态演示'),'演示重启'));
   match('button',/^检查更新$/,()=>go('update.html'));
   $$('.drop').forEach(el=>link(el,()=>modal('界面语言','仅记录语言选择的设计交互。',[{label:'语言',name:'language',options:['跟随系统','简体中文','English']}],d=>{el.textContent=d.language;save('language',d.language)},'选择')));
 }
 if(file==='folder-detail.html'){
   match('button',/^复制$/,b=>copy(text($('.v',b.closest('.key')))+'（演示密钥，不能连接）'));
   match('button',/^邮件 \/ QR$/,()=>modal('分享示例','这是不可用于连接的示例密钥。原型不发送邮件，也不伪造可用二维码。',[{label:'示例只读密钥',name:'key',value:'DEMO-READONLY-NOT-A-REAL-KEY'}]));
   const view=$('.view'),original=[...view.childNodes];view.setAttribute('aria-label','文件夹详情内容');
   const tabs=$('.tabs .tab');
   function activate(tab){tabs.forEach(t=>{const active=t===tab;t.classList.toggle('active',active);t.setAttribute('aria-current',active?'true':'false')});}
   tabs.forEach((tab,i)=>{tab.setAttribute('aria-current',i===0?'true':'false')});
   tabs.forEach((tab,i)=>link(tab,()=>{activate(tab);if(i===0)view.replaceChildren(...original);else if(i===1)view.innerHTML='<div class="card"><h2>传输样例</h2><p>proposal.md · 正在接收 · 62%</p></div>';else if(i===2)view.innerHTML='<div class="card"><h2>历史样例</h2><p>示例设备接入 · 14 分钟前</p></div>';else go('settings.html')}));
 }
 if(file==='update.html'){
   match('button',/^关闭$/,()=>go('settings.html'));
   match('button',/^打开所在文件夹$/,()=>modal('下载文件样例','原型不下载或安装客户端。此处用于评审签名验证完成后的打开位置入口。'));
 }
 if(file!=='folders.html'){const a=document.createElement('a');a.className='proto-context';a.href='folders.html';a.textContent='← 返回文件夹';document.body.prepend(a)}
})();
