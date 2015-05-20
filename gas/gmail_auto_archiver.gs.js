// https://script.google.com/d/1mSeTLYg1qUm553FH5XXh9yTafT_k7OKbcTKE_xJlwyqsFactFwsg-q5s/edit?usp=sharing
function autoArchiver() {
  QUERY = 'label:auto-archive in:inbox';
  
  var threshold = new Date((new Date()) - (1000 * 60 * 60 * 20)); // 20 hr  
  
  Logger.log("Starting...");
  Logger.log("Threshold: %s", threshold.toString());
  
  while ( true ) {
    var archiveThreads = [];
    
    Logger.log("=> Query: %s", QUERY);
    var threads = GmailApp.search(QUERY, 0, 100);
    Logger.log(" * Hit %s threads", threads.length);
    
    for ( var i = 0; i < threads.length; i++ ) {
      var thread = threads[i];
      var lastDate = thread.getLastMessageDate();
      if ( lastDate < threshold ) {
        Logger.log(" - %s: %s", thread.getLastMessageDate(), thread.getFirstMessageSubject());
        archiveThreads.push(thread);
      }
      Utilities.sleep(500);
    }
    
    if ( archiveThreads.length < 1 ) {
      break;
    }
    Logger.log("=> Archiving %s threads", archiveThreads.length);
    GmailApp.moveThreadsToArchive(archiveThreads);
    
    Logger.log(" * Done, sleeping 1 sec");
    Utilities.sleep(1000);
  }
  
  Logger.log("DONE.");
}
