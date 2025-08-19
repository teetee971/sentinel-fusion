import "dotenv/config"; import axios from "axios"; import { bus } from "../orchestrator.js";
const SITE_URL=(process.env.SITE_URL||"").trim();
const log=(...a)=>console.log(new Date().toISOString(),"[monitor]",...a);
async function check(){
  if(!SITE_URL) return log("SITE_URL manquant");
  try{
    const t0=Date.now(); const r=await axios.get(SITE_URL,{timeout:12000,validateStatus:()=>true});
    const ms=Date.now()-t0;
    if(r.status>=200&&r.status<400){ log(`OK ${r.status} ${ms}ms`); bus.emit("monitor:ok"); }
    else{ log(`DOWN ${r.status} ${ms}ms`); bus.emit("monitor:fail"); bus.emit("site:down",{code:r.status,ms}); bus.emit("diagnose",{summary:`HTTP ${r.status} ${ms}ms sur ${SITE_URL}`}); }
  }catch(e){ log("ERR", e.code||e.message); bus.emit("monitor:fail"); bus.emit("site:down",{code:e.code||"ERR"}); bus.emit("diagnose",{summary:`Exception ${e.code||e.message} sur ${SITE_URL}`}); }
}
setInterval(check,60_000); bus.on("monitor:checkOnce",check); check();
