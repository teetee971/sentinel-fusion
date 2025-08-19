import { bus } from "../orchestrator.js";
const log=(...a)=>console.log(new Date().toISOString(),"[fix]",...a);
bus.on("site:down",({code})=>{ log("Auto-fix armé après détection:", code); });
