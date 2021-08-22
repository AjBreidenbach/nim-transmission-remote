import asyncdispatch, asyncfutures, httpclient, json, marshal, sequtils


type TransmissionRemote* = ref object
  url: string
  client: AsyncHttpClient
  sessionId: string
  removeLocalData: bool
  

type AddTorrentResponse* = object
  hashString: string
  id: int
  name: string
  responseType: string


type TorrentAddOptions = distinct JsonNode

proc newTorrentAddOptions(): TorrentAddOptions = TorrentAddOptions newJObject()


template torrentAddOptionParameter(symbol: untyped, parameterType: untyped, rpcName: string = ""): untyped =
  proc `symbol=`*(self: TorrentAddOptions, symbol: parameterType) {.inject.}=
    when rpcName == "":
      let name = astToStr(symbol)
      JsonNode(self)[name] = % symbol
    else:
      JsonNode(self)[rpcName] = % symbol


torrentAddOptionParameter(cookies, string)
torrentAddOptionParameter(downloadDir, string, "download-dir")
torrentAddOptionParameter(filename, string)
torrentAddOptionParameter(metainfo, string)
torrentAddOptionParameter(paused, bool)
torrentAddOptionParameter(peerLimit, int, "peer-limit")
torrentAddOptionParameter(bandwidthPriority, int)
torrentAddOptionParameter(filesWanted, openarray[int], "files-wanted")
torrentAddOptionParameter(filesUnwanted, openarray[int], "files-unwanted")
torrentAddOptionParameter(priorityHigh, openarray[int], "priority-high")
torrentAddOptionParameter(priorityLow, openarray[int], "priority-low")
torrentAddOptionParameter(priorityNormal, openarray[int], "priority-normal")


type FileInfo* = object
  bytesCompleted: int
  length: int
  name: string

type FileStats* = object
  bytesCompleted: int
  wanted: bool
  priority: int

type Peer* = object
  address: string
  clientName: string
  clientIsChoked: bool
  clientIsInterested: bool
  flagStr: string
  isDownloadingFrom: bool
  isEncrypted: bool
  isIncoming: bool
  isUploadingTo: bool
  isUTP: bool
  peerIsChoked: bool
  peerIsInterested: bool
  port: int
  progress: float
  rateToClient: int
  rateToPeer: int


type PeerStats* = object
  fromCache: int
  fromDht: int
  fromIncoming: int
  fromLpd: int
  fromLtep: int
  fromPex: int
  fromTracker: int


type Tracker* = object
  announce: string
  id: int
  scrape: string
  tier: int


type TrackerStats* = object
  announce: string
  announceState: int
  downloadCount: int
  hasAnnounced: bool
  hasScraped: bool
  host: string
  id: int
  isBackup: bool
  lastAnnouncePeerCount: int
  lastAnnounceResult: string
  lastAnnounceStartTime: int
  lastAnnounceSucceeded: bool
  lastAnnounceTime: int
  lastAnnounceTimeOut: bool
  lastScrapeResult: string
  lastScrapeStartTime: int
  lastScrapeTimeOut: bool
  leecherCount: int
  nextAnnounceTime: int
  nextScrapeTime: int
  scrape: string
  scraperState: int
  seederCount: int
  tier: int
  

type Key* {.pure.} = enum
  activityDate = "activityDate"
  addedDate = "addedDate"
  bandwidthPriority = "bandwidthPriority"
  comment = "comment"
  corruptEver = "corruptEver"
  creator = "creator"
  dateCreated = "dateCreated"
  desiredAvailable = "desiredAvailable"
  doneDate = "doneDate"
  downloadDir = "downloadDir"
  downloadedEver = "downloadedEver"
  downloadLimit = "downloadLimit"
  downloadLimited = "downloadLimited"
  editDate = "editDate"
  error = "error"
  errorString = "errorString"
  eta = "eta"
  etaIdle = "etaIdle"
  fileCount = "file-count"
  files = "files"
  fileStats = "fileStats"
  hashString = "hashString"
  haveUnchecked = "haveUnchecked"
  haveValid = "haveValid"
  honorsSessionLimits = "honorsSessionLimits"
  id = "id"
  isFinished = "isFinished"
  isStalled = "isStalled"
  isPrivate = "isPrivate"
  labels = "labels"
  leftUntilDone = "leftUntilDone"
  magnetLink = "magnetLink"
  manualAnnounceTime = "manualAnnounceTime"
  maxConnectedPeers = "maxConnectedPeers"
  metadataPercentComplete = "metadataPercentComplete"
  name = "name"
  peerLimit = "peer-limit"
  peers = "peers"
  peersConnected = "peersConnected"
  peersFrom = "peersFrom"
  peersGettingFromUs = "peersGettingFromUs"
  peersSendingToUs ="peersSendingToUs"
  percentDone = "percentDone"
  pieces = "pieces"
  pieceCount = "pieceCount"
  pieceSize = "pieceSize"
  priorities = "priorities"
  primaryMimeType = "primary-mime-type"
  queuePosition = "queuePosition"
  rateDownload = "rateDownload"
  rateUpload = "rateUpload"
  recheckProgress = "recheckProgress"
  secondsDownloading = "secondsDownloading"
  secondsSeeding = "secondsSeeding"
  seedIdleLimit = "seedIdleLimit"
  seedIdleMode = "seedIdleMode"
  seedRatioLimit = "seedRatioLimit"
  seedRatioMode = "seedRatioMode"
  sizeWhenDone = "sizeWhenDone"
  startDate = "startDate"
  status = "status"
  trackers = "trackers"
  trackerStats = "trackerStats"
  totalSize = "totalSize"
  torrentFile = "torrentFile"
  uploadedEver = "uploadedEver"
  uploadLimit = "uploadLimit"
  uploadLimited = "uploadLimited"
  uploadRatio = "uploadRatio"
  wanted = "wanted"
  webseeds = "webseeds"
  webseedsSendingToUs = "webseedsSendingToUs"

  filesWanted = "files-wanted"
  filesUnwanted = "files-unwanted"
  ids="ids"
  location="location"
  priorityHigh="priority-high"
  priorityLow="priority-low"
  priorityNormal="priority-normal"
  trackerAdd
  trackerRemove
  
  



type TorrentProperties = object
  node: JsonNode

template torrentOptionSetter(symbol:untyped, parameterType:untyped, mutable=false): untyped =
  when mutable:
    proc `symbol=`*(t: TorrentProperties, value: parameterType) {.inject.} =
      t.node[$Key.symbol] = %value
  else:
    proc `symbol=`(t: TorrentProperties, value: parameterType) =
      t.node[$Key.symbol] = %value

  proc `symbol`*(t: TorrentProperties): parameterType {.inject.} =
    t.node[$Key.symbol].to(parameterType)
    
proc newTorrentProperties(): TorrentProperties = TorrentProperties(node: newJObject())

torrentOptionSetter(bandwidthPriority, int, true)
torrentOptionSetter(downloadLimit, int, true)
torrentOptionSetter(downloadLimited, bool, true)
torrentOptionSetter(filesWanted, seq[string], true)
torrentOptionSetter(filesUnwanted, seq[string], true)
torrentOptionSetter(honorsSessionLimits, bool, true)
torrentOptionSetter(ids, seq[int], true)
torrentOptionSetter(labels, seq[string], true)
torrentOptionSetter(location, string, true)
torrentOptionSetter(peerLimit, int, true)
torrentOptionSetter(priorityHigh, seq[int], true)
torrentOptionSetter(priorityLow, seq[int], true)
torrentOptionSetter(priorityNormal, seq[int], true)
torrentOptionSetter(queuePosition, int, true)
torrentOptionSetter(seedIdleLimit, int, true)
torrentOptionSetter(seedIdleMode, int, true)
torrentOptionSetter(seedRatioLimit, float, true)
torrentOptionSetter(seedRatioMode, int, true)
torrentOptionSetter(trackerAdd, seq[string], true)
torrentOptionSetter(trackerRemove, seq[int], true)
#torrentOptionSetter(trackerReplace, seq[int], true)
#TODO what is the parameterType on this
torrentOptionSetter(uploadLimit, int, true)
torrentOptionSetter(uploadLimited, bool, true)

torrentOptionSetter(activityDate, int)
torrentOptionSetter(addedDate, int)
torrentOptionSetter(comment, string)
torrentOptionSetter(corruptEver, int)
torrentOptionSetter(creator, string)
torrentOptionSetter(dateCreated, int)
torrentOptionSetter(desiredAvailable, int)
torrentOptionSetter(doneDate, int)
torrentOptionSetter(downloadDir, string)
torrentOptionSetter(downloadedEver, int)
torrentOptionSetter(editDate, int)
torrentOptionSetter(error, int)
torrentOptionSetter(errorString, string)
torrentOptionSetter(eta, int)
torrentOptionSetter(etaIdle, int)
torrentOptionSetter(fileCount, int)
torrentOptionSetter(files, seq[FileInfo])
torrentOptionSetter(fileStats, seq[FileStats])
torrentOptionSetter(hashString, string)
torrentOptionSetter(haveUnchecked, int)
torrentOptionSetter(haveValid, int)
torrentOptionSetter(honorsSessionLimits, bool)
torrentOptionSetter(id, int)
torrentOptionSetter(isFinished, bool)
torrentOptionSetter(isPrivate, bool)
torrentOptionSetter(isStalled, bool)
torrentOptionSetter(labels, seq[string])
torrentOptionSetter(leftUntilDone, int)
torrentOptionSetter(magnetLink, string)
torrentOptionSetter(manualAnnounceTime, int)
torrentOptionSetter(maxConnectedPeers, int)
torrentOptionSetter(metadataPercentComplete, float)
torrentOptionSetter(name, string)
torrentOptionSetter(peers, seq[Peer])
torrentOptionSetter(peersConnected, int)
torrentOptionSetter(peersFrom, seq[PeerStats])
torrentOptionSetter(peersGettingFromUs, int)
torrentOptionSetter(peersSendingToUs, int)
torrentOptionSetter(percentDone, float)
torrentOptionSetter(pieces, string)
torrentOptionSetter(pieceCount, int)
torrentOptionSetter(pieceSize, int)
#priorities
torrentOptionSetter(primaryMimeType, string)
torrentOptionSetter(queuePosition, int)
torrentOptionSetter(rateDownload, int)
torrentOptionSetter(rateUpload, int)
torrentOptionSetter(recheckProgress, float)
torrentOptionSetter(secondsDownloading, int)
torrentOptionSetter(secondsSeeding, int)
torrentOptionSetter(startDate, int)
torrentOptionSetter(status, int)
torrentOptionSetter(trackers, seq[Tracker])
torrentOptionSetter(trackerStats, seq[TrackerStats])
torrentOptionSetter(totalSize, int)
torrentOptionSetter(torrentFile, string)
torrentOptionSetter(uploadedEver, int)
torrentOptionSetter(uploadRatio, float)
#wanted
torrentOptionSetter(webseeds, seq[string])
torrentOptionSetter(webseedsSendingToUs, int)




proc newTransmissionRemote*(host="localhost", path="/transmission/rpc", port=9091, ssl=false, removeLocalData=false): TransmissionRemote =
  TransmissionRemote(
    url: "http://" & host & ':' & $port & path,
    client: newAsyncHttpClient(),
    sessionId: "",
    removeLocalData: removeLocalData
  )



proc postJSON(tr: TransmissionRemote, payload: JsonNode): Future[AsyncResponse] {.async.} =
  let headers = newHttpHeaders({"Content-Type": "application/json", "X-Transmission-Session-Id": tr.sessionId})
  result = await tr.client.request(tr.url, HttpPost, $payload, headers)
  tr.sessionId = result.headers.getOrDefault("X-Transmission-Session-Id", HttpHeaderValues(@[tr.sessionId]))
  if result.status == Http409:
    result = await postJSON(tr, payload)

  echo payload
  return result
  
  
proc postAdd(tr: TransmissionRemote, data: JsonNode): Future[AddTorrentResponse] {.async.} =
  let response = await tr.postJSON(data)
  let body = parseJson(await response.body)
  let arguments = body["arguments"]

  try:
    let torrentAdded = arguments["torrent-added"]

    result = to[AddTorrentResponse] $torrentAdded
    result.responseType = "torrentAdded"
    return

  except: discard

  try:
    let torrentDuplicate = arguments["torrent-duplicate"]

    result = to[AddTorrentResponse] $torrentDuplicate
    result.responseType = "torrentDuplicate"
    return

  except: discard

proc addTorrent*(tr: TransmissionRemote, options: TorrentAddOptions): Future[AddTorrentResponse] =
  let serialized = %* {
    "arguments": JsonNode(options),
    "method": %"torrent-add"
  }

  tr.postAdd(serialized)


proc addTorrent*(tr: TransmissionRemote,
download_dir="",filename="",metainfo="",paused=false
): Future[AddTorrentResponse] =
  var torrentOptions = newTorrentAddOptions()
  if download_dir.len != 0: torrentOptions.downloadDir=download_dir
  if filename.len != 0: torrentOptions.filename=filename
  if metainfo.len != 0: torrentOptions.metainfo=metainfo
  if paused: torrentOptions.paused=paused

  tr.addTorrent(torrentOptions)
  

proc getTorrentsInner(tr: TransmissionRemote,
                 ids: seq[int]= @[], requestedProperties: seq[Key] = @[Key.id]): Future[seq[TorrentProperties]] {.async.}=


  let payload = %*{
    "method": "torrent-get",
    "arguments": {
      "fields": %requestedProperties.mapIt($it)
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  echo payload
  let response = await tr.postJSON(payload)


  let arguments = parseJson(await response.body)["arguments"]
  result = arguments["torrents"].getElems().mapIt(TorrentProperties(node: it))

proc getTorrents*(tr: TransmissionRemote, ids: openarray[int], requestedProperties: varargs[Key]): Future[seq[TorrentProperties]] =
  return tr.getTorrentsInner(@ids, @requestedProperties)


proc getTorrentInner(tr: TransmissionRemote, id: int, requestedProperties: seq[Key] = @[Key.id]): Future[TorrentProperties] {.async.} =
  result = (await tr.getTorrentsInner(@[id], requestedProperties))[0]

proc getTorrent*(tr: TransmissionRemote, id: int, requestedProperties: varargs[Key]): Future[TorrentProperties] =
  return tr.getTorrentInner(id, @requestedProperties)

  
proc voidResponse(f: Future[AsyncResponse]): Future[void] {.async.} =
  let response = await f
  echo await response.body

proc removeTorrents*(tr: TransmissionRemote, ids: varargs[int] = []): Future[void] =
  let payload = %*{
    "method": "torrent-remove",
    "arguments": {
      "delete-local-data": %tr.removeLocalData
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  return voidResponse(tr.postJSON(payload))


proc removeTorrentsAndData*(tr: TransmissionRemote, ids: varargs[int] = []): Future[void] =
  let payload = %*{
    "method": "torrent-remove",
    "arguments": {
      "delete-local-data": %true
    }
  }

  if ids.len > 0:
    payload["arguments"]["ids"] = %ids

  return voidResponse(tr.postJSON(payload))

proc removeTorrent*(tr: TransmissionRemote, id: int, deleteLocalData = false): Future[void] =
  if deleteLocalData: tr.removeTorrentsAndData(id)
  else: tr.removeTorrents(id)

proc removeTorrentAndData*(tr: TransmissionRemote, id: int): Future[void] =
  tr.removeTorrentsAndData(id)

