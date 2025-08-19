import "dotenv/config"; import axios from "axios"; import { bus } from "../orchestrator.js";
const DEPLOY_HOOK_URL=(process.env.DEPLOY_HOOK_URL||"").trim();
const log=(...a)=>console.log(new Date().toISOString(),"[deploy]",...a);
async function trigger(reason="manual"){
  if(!DEPLOY_HOOK_URL) return log("DEPLOY_HOOK_URL manquant");
  try{ await axios.post(DEPLOY_HOOK_URL,{}); log("✅ Deploy déclenché (",reason,")"); }
  catch(e){ log("❌ Deploy KO:", e.response?.data||e.message); }
}
bus.on("deploy:trigger",({reason}={reason:"bus"})=>trigger(reason));
if(process.argv[1]?.endsWith("deploy.js")) trigger("manual");
