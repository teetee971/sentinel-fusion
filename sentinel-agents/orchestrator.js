import "dotenv/config";
import { EventEmitter } from "node:events";
import { setTimeout as wait } from "node:timers/promises";
import axios from "axios";
export const bus = new EventEmitter();
const env=(k,d="")=>(process.env[k]??d).trim();
const SITE_URL=env("SITE_URL"), DEPLOY_HOOK_URL=env("DEPLOY_HOOK_URL");
const CF_API_TOKEN=env("CF_API_TOKEN"), ACCOUNT_ID=env("ACCOUNT_ID");
const PROJECT_NAME=env("PROJECT_NAME","sentinelquantumvanguardiapro");
const OPENAI_API_KEY=env("OPENAI_API_KEY"), OPENAI_MODEL=env("OPENAI_MODEL","gpt-4o");
const log=(...a)=>console.log(new Date().toISOString(),"-",...a);

await import("./agents/monitor.js"); await import("./agents/deploy.js");
await import("./agents/fix.js"); await import("./agents/ui.js");
log("Orchestrateur prêt. SITE_URL:", SITE_URL||"(manquant)");

let cooldown=false, failures=0;
bus.on("monitor:ok",()=>{ failures=0; });
bus.on("monitor:fail",()=>{ if(++failures>=3){ failures=0; log("🚨 3 échecs → redeploy"); bus.emit("deploy:trigger",{reason:"watchdog"}); }});
bus.on("site:down", async p=>{
  if(cooldown) return;
  cooldown=true; log("⚠️  Down:", p);
  if(CF_API_TOKEN&&ACCOUNT_ID&&PROJECT_NAME){
    try{ const url=`https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/purge_cache`;
      await axios.post(url,{}, {headers:{Authorization:`Bearer ${CF_API_TOKEN}`}}); log("✅ Purge CF Pages"); }
    catch(e){ log("❌ Purge KO:", e.response?.data||e.message); }
  }
  bus.emit("deploy:trigger",{reason:"auto-repair"});
  await wait(45_000); bus.emit("monitor:checkOnce");
  await wait(120_000); cooldown=false;
});
bus.on("diagnose", async ({summary})=>{
  if(!OPENAI_API_KEY) return;
  try{
    const r=await axios.post("https://api.openai.com/v1/chat/completions",
      {model:OPENAI_MODEL,messages:[{role:"system",content:"Ingénieur fiabilité, réponse courte."},{role:"user",content:`Diagnostic panne:\n${summary}`}]},
      {headers:{Authorization:`Bearer ${OPENAI_API_KEY}`}});
    console.log(new Date().toISOString(),"- 🧠", r.data.choices?.[0]?.message?.content?.trim()||"");
  }catch(e){ log("LLM err:", e.response?.data||e.message); }
});
