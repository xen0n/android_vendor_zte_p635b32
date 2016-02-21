#!/bin/bash

SOURCE=$1
TARGET=.


make_multilib_paths () {
	LIB32_PATH=$1
	LIB64_PATH="$( sed 's@/lib/@/lib64/@g;' <(echo ${LIB32_PATH}) )"
	echo "${LIB32_PATH} ${LIB64_PATH}"
}


#
# wifi and gsm firmware's
#
FIRMWARE="/etc/firmware/"

#
# wmt_loader init kernel device modules, then waits for autokd. after autokd finishes its work,
# wmt_loader inits /dev/stpwmt, then 6620_launcher proceeds to load a firmware to the CPU using /dev/stpwmt.
#
WIFI="/etc/wifi/ /bin/6620_wmt_lpbk /bin/6620_launcher /bin/6620_wmt_concurrency /bin/wmt_loader \
/bin/autokd \
"

BLUETOOTH32="\
/lib/libbluetoothdrv.so /lib/libbluetooth_mtk.so \
/lib/libbtcusttable.so \
/lib/libbtstd.so \
/lib/libextsys.so /lib/libextsys_jni.so \
/lib/libbluetoothem_mtk.so /lib/libbluetooth_relayer.so \
/lib/libbtem.so \
"
BLUETOOTH="\
/bin/mtkbt \
/lib/libadpcm.so /lib/libbtcust.so /lib/libbtcusttc1.so \
/lib/libbtsession.so /lib/libbtpcm.so /lib/libbtsniff.so \
/lib/libpalsecurity.so /lib/libpalwlan_mtk.so \
/lib/libsbccodec.so \
$(make_multilib_paths "${BLUETOOTH32}")
"

# 
# gralloc && hwcomposer - hardware layer. rest is userspace lib.so layer.
#
GL32="\
/lib/egl/libGLES_mali.so \
/lib/libm4u.so /lib/hw/gralloc.mt6735.so /lib/hw/hwcomposer.mt6735.so /lib/libbwc.so /lib/libgpu_aux.so \
/lib/libgralloc_extra.so /lib/libdpframework.so /lib/libion.so /lib/libion_mtk.so /lib/libged.so \
/lib/libaed.so /lib/libmtk_drvb.so /lib/libpq_prot.so /lib/libgui_ext.so /lib/libui_ext.so \
/lib/libvcodecdrv.so /lib/libvcodec_utility.so \
lib/libvc1dec_sa.ca7.so lib/libvp8dec_sa.ca7.so lib/libvp8enc_sa.ca7.so \
lib/libvp9dec_sa.ca7.so \
/lib/libperfservice.so /lib/libperfservicenative.so \
"
GL="\
/bin/guiext-server /bin/pq \
/lib/libvcodec_oal.so \
$(make_multilib_paths "${GL32}")
"

# Digital Restrictions Management
DRM32="/vendor/lib/mediadrm/libdrmclearkeyplugin.so /vendor/lib/mediadrm/libmockdrmcryptoplugin.so \
/lib/libdrmmtkutil.so /lib/libdrmmtkwhitelist.so \
/lib/libnvramagentclient.so \
"
DRM="\
/vendor/lib/libwvm.so /vendor/lib/libwvdrm_L3.so /vendor/lib/libWVStreamControlAPI_L3.so \
/vendor/lib/drm/libdrmwvmplugin.so \
/vendor/lib/mediadrm/libwvdrmengine.so \
/lib/drm/libdrmctaplugin.so /lib/drm/libdrmmtkplugin.so \
$(make_multilib_paths "${DRM32}")
"

# Codecs
CODECS32="/lib/libstagefrighthw.so \
/lib/libMtkOmxAdpcmDec.so /lib/libMtkOmxAdpcmEnc.so /lib/libMtkOmxAlacDec.so /lib/libMtkOmxApeDec.so \
/lib/libMtkOmxCore.so /lib/libMtkOmxFlacDec.so /lib/libMtkOmxG711Dec.so /lib/libMtkOmxGsmDec.so \
/lib/libMtkOmxMp3Dec.so /lib/libMtkOmxRawDec.so /lib/libMtkOmxVdec.so /lib/libMtkOmxVenc.so /lib/libMtkOmxVorbisEnc.so \
/lib/libmhalImageCodec.so /lib/libmmprofile.so /lib/libmtb.so \
/lib/libJpgDecPipe.so /lib/libGdmaScalerPipe.so /lib/libSwJpgCodec.so /lib/libJpgEncPipe.so /lib/libmtkjpeg.so \
/lib/libstagefright_amrnb_common.so /lib/libstagefright_avc_common.so /lib/libstagefright_enc_common.so \
/lib/libstagefright_soft_ffmpegadec.so \
/lib/extend/libCodec.adt.so /lib/extend/libCodec.adpcmdec.so /lib/extend/libCodec.alacdec.so /lib/extend/libCodec.ape.so \
/lib/extend/libCodec.dsddec.so /lib/extend/libCodec.dts.so /lib/extend/libCodec.lpcm.so /lib/extend/libCodec.mp3dec.so \
/lib/extend/libCodec.mp3enc.so /lib/extend/libCodec.mpegdec.so /lib/extend/libCodec.radec.so /lib/extend/libCodec.raw.so \
/lib/extend/libCodec.rvdec.so /lib/extend/libCodec.wmadec.so \
/lib/extend/libExtractor.AC3.so /lib/extend/libExtractor.AIFF.so /lib/extend/libExtractor.APE.so /lib/extend/libExtractor.ASF.so \
/lib/extend/libExtractor.AVI.so /lib/extend/libExtractor.DTS.so \
/lib/extend/libExtractor.FLAC.so /lib/extend/libExtractor.FLV.so /lib/extend/libExtractor.MP3.so /lib/extend/libExtractor.MPEG.so \
/lib/extend/libExtractor.MPEG2TS.so /lib/extend/libExtractor.MPEG4.so /lib/extend/libExtractor.REALMEDIA.so \
/lib/extend/libExtractor.WAV.so /lib/extend/libExtractor.matroska.so \
/lib/libBnMtkCodec.so \
"
CODECS="\
/etc/mtk_omx_core.cfg \
/bin/MtkCodecService \
$(make_multilib_paths "${CODECS32}")
"

#
# ccci_mdinit starts, depends on additional services:
# - drvbd - unix socket connection - no longer exists on Lollipop+
# - nvram - folders /data/nvram, modem settings like IMEI
# - gsm0710muxd - /dev/radio/ ports for accessing the modem 
# - mdlogger
# - ccci_fsd
#
# ccci_mdinit loads modem_1_wg_n.img firmware to the CPU, waits for NVRAM to init using ENV variable.
# then starts the modem CPU. on success starts rest services mdlogger, gsm0710muxd ...
#
# ccci_fsd periodically says "Waiting permission check ready!", checking for a file called
# /data/nvram/md_new_ver.1 which obviously doesn't exist. Upon grepping this string a binary
# called permission_check popped out...
#
RIL32="/lib/mtk-ril.so /lib/mtk-rilmd2.so /lib/librilmtk.so /lib/librilmtkmd2.so \
/lib/libnvram.so /lib/libcustom_nvram.so /lib/libnvram_sec.so \
/lib/libhwm.so /lib/libnvram_platform.so /lib/libfile_op.so /lib/libnvram_daemon_callback.so \
/lib/libmdloggerrecycle.so \
/lib/libatciserv_jni.so /lib/libaal.so \
/lib/libccci_util.so \
"
RIL="\
/bin/nvram_daemon /bin/nvram_agent_binder /bin/aee \
/bin/gsm0710muxd /bin/gsm0710muxdmd2 /bin/ccci_fsd /bin/ccci_mdinit \
/bin/atci_service /bin/atcid /bin/audiocmdservice_atci /bin/permission_check \
/bin/md_ctrl /bin/muxreport /bin/mtkrild /bin/mtkrildmd2 \
/bin/terservice /lib64/libterservice.so \
/lib/libexttestmode.so \
$(make_multilib_paths "${RIL32}")
"

AUDIO="/lib/hw/audio.primary.mt6735.so /lib/libblisrc.so /lib/libspeech_enh_lib.so /lib/libaudiocustparam.so /lib/libaudiosetting.so \
/lib/libaudiocompensationfilter.so /lib/libcvsd_mtk.so /lib/libmsbc_mtk.so /lib/libaudiocomponentengine.so \
/lib/libblisrc32.so /lib/libbessound_hd_mtk.so /lib/libmtklimiter.so /lib/libmtkshifter.so /lib/libaudiodcrflt.so \
/lib/libtfa9890_interface.so /lib/libtinyxml.so \
/etc/tfa98xx/ /etc/audio_device.xml \
"

#CAMERA="/lib/hw/camera.mt6735.so \
#/lib/libcamera_client_mtk.so /lib/libcam.halsensor.so /lib/libcam_hwutils.so /lib/libcam_utils.so /lib/libmeizucamera.so /lib/libmeizu.camera.algo.so /lib/libmmsdkservice.so /lib/libmmsdkservice.feature.so \
#/lib/libcam1_utils.so /lib/libcamalgo.so /lib/libcam.camadapter.so /lib/libcam.camnode.so /lib/libcam.camshot.so /lib/libcam.client.so \
#/lib/libcam.common.meizu.so /lib/libcam.device1.so /lib/libcamdrv.so /lib/libcameracustom.so /lib/libcam.exif.so /lib/libcam.iopipe.so \
#/lib/libcam.jni.lomohaljni.so /lib/libcam.metadata.so /lib/libcam_mmp.so /lib/libcam.paramsmgr.so /lib/libcam_platform.so \
#/lib/libcam.sdkclient.so /lib/libcam.utils.sensorlistener.so /lib/libcam.utils.so /lib/libcam.utils.cpuctrl.so \
#/lib/libdngop.so /lib/libfeatureio.so /lib/libimageio_plat_drv.so /lib/libimageio.so /lib/libmatv_cust.so \
#/lib/libmpoencoder.so /lib/libmpo.so \
#/lib/libmtk_mmutils.so /vendor/lib/libsfb.so /lib/libvideo_render.so /lib/libvideostabilizer.so \
#/lib/lib3a.so /lib/lib3a_sample.so /lib/libgraphite2.so /lib/libn3d3a.so /lib/libtiff.so /lib/libtouchfilter.so \
#"

SENSORS="/lib/hw/sensors.mt6735.so \
/lib/libinvensense_hal.so /lib/libmllite.so \
/bin/geomagneticd /bin/magd /bin/orientationd \
"

GPS="/lib/hw/gps.default.so /bin/mtk_agpsd /bin/wifi2agps /xbin/mnld /xbin/BGW /xbin/MPED \
/lib/libcurl.so /lib/libssladp.so /lib/libmnl.so /lib/libDR.so /lib/libfusion.so /lib/libmpe.driver.so /lib/libmpe.sensorlistener.so \
"

CHARGER="/bin/kpoc_charger /lib/libshowlogo.so /lib/libsuspend.so"

MISC="/bin/akmd8963 /bin/akmd8975 /bin/ami304d /bin/bmm050d /bin/mc6420d /bin/memsicd /bin/memsicd3416x \
/bin/s62xd /bin/thermal /bin/thermald /bin/thermal_manager \
/bin/ppl_agent /bin/matv \
/bin/immvibed /lib/libpparam.so \
"

#SYSTEM="$FIRMWARE $WIFI $GL $DRM $CODECS $RIL $AUDIO $BLUETOOTH $CAMERA $SENSORS $GPS $CHARGER $MISC"
SYSTEM="$FIRMWARE $WIFI $BLUETOOTH $GL $DRM $RIL $CHARGER"

rename_file () {
	local src
	local dest

	if [[ "x$1" == "x-b" ]]; then
		src=$3
		dest=$2
	else
		src=$1
		dest=$2
	fi

	mv $TARGET/$src $TARGET/$dest
}

move_files () {
	# unneeded as of Lollipop
	#rename_file $1 lib/hw/audio.primary.mt6735.so lib/libaudio.primary.default.so
	#rename_file $1 vendor/lib/hw/audio.a2dp.blueangel.so vendor/lib/hw/audio.a2dp.mt6735.so
	true
}

# get data from a device
if [ -z $SOURCE ]; then
  for FILE in $SYSTEM ; do
    T=$TARGET/$FILE
    adb pull /system/$FILE $T
  done
  move_files
  exit 0
fi

# get data from folder
move_files -b
for FILE in $SYSTEM ; do
  S=$SOURCE/$FILE
  T=$TARGET/$FILE
  mkdir -p $(dirname $T) || exit 1
  rsync -av --delete $S $T || exit 1
done
move_files
exit 0

