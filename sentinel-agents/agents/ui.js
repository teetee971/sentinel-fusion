import { bus } from "../orchestrator.js";
const log=(...a)=>console.log(new Date().toISOString(),"[ui]",...a);
bus.on("monitor:ok",()=>{ /* futur préchauffage */ });
log("Agent UI prêt.");
