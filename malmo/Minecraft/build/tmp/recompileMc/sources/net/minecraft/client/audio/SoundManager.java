package net.minecraft.client.audio;

import com.google.common.collect.BiMap;
import com.google.common.collect.HashBiMap;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Multimap;
import io.netty.util.internal.ThreadLocalRandom;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import net.minecraft.client.Minecraft;
import net.minecraft.client.settings.GameSettings;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.util.MathHelper;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.Marker;
import org.apache.logging.log4j.MarkerManager;
import paulscode.sound.SoundSystem;
import paulscode.sound.SoundSystemConfig;
import paulscode.sound.SoundSystemException;
import paulscode.sound.SoundSystemLogger;
import paulscode.sound.Source;
import paulscode.sound.codecs.CodecJOrbis;
import paulscode.sound.libraries.LibraryLWJGLOpenAL;

import net.minecraftforge.client.ForgeHooksClient;
import net.minecraftforge.client.event.sound.*;
import net.minecraftforge.common.MinecraftForge;

@SideOnly(Side.CLIENT)
public class SoundManager
{
    /** The marker used for logging */
    private static final Marker LOG_MARKER = MarkerManager.getMarker("SOUNDS");
    private static final Logger logger = LogManager.getLogger();
    /** A reference to the sound handler. */
    public final SoundHandler sndHandler;
    /** Reference to the GameSettings object. */
    private final GameSettings options;
    /** A reference to the sound system. */
    private SoundManager.SoundSystemStarterThread sndSystem;
    /** Set to true when the SoundManager has been initialised. */
    private boolean loaded;
    /** A counter for how long the sound manager has been running */
    private int playTime = 0;
    /** Identifiers of all currently playing sounds. Type: HashBiMap<String, ISound> */
    private final Map playingSounds = HashBiMap.create();
    /** Inverse map of currently playing sounds, automatically mirroring changes in original map */
    private final Map invPlayingSounds;
    /** A HashMap<String, SoundPoolEntry> of the playing sounds. */
    private Map playingSoundPoolEntries;
    /** Contains sounds mapped by category. Type: Multimap<SoundCategory, String> */
    private final Multimap categorySounds;
    /** A subset of playingSounds, this contains only ITickableSounds */
    private final List tickableSounds;
    /** Contains sounds to play in n ticks.  Type: HashMap<ISound, Integer> */
    private final Map delayedSounds;
    /** The future time in which to stop this sound.  Type: HashMap<String, Integer> */
    private final Map playingSoundsStopTime;
    private static final String __OBFID = "CL_00001141";

    public SoundManager(SoundHandler p_i45119_1_, GameSettings p_i45119_2_)
    {
        this.invPlayingSounds = ((BiMap)this.playingSounds).inverse();
        this.playingSoundPoolEntries = Maps.newHashMap();
        this.categorySounds = HashMultimap.create();
        this.tickableSounds = Lists.newArrayList();
        this.delayedSounds = Maps.newHashMap();
        this.playingSoundsStopTime = Maps.newHashMap();
        this.sndHandler = p_i45119_1_;
        this.options = p_i45119_2_;

        try
        {
            SoundSystemConfig.addLibrary(LibraryLWJGLOpenAL.class);
            SoundSystemConfig.setCodec("ogg", CodecJOrbis.class);
            MinecraftForge.EVENT_BUS.post(new SoundSetupEvent(this));
        }
        catch (SoundSystemException soundsystemexception)
        {
            logger.error(LOG_MARKER, "Error linking with the LibraryJavaSound plug-in", soundsystemexception);
        }
    }

    public void reloadSoundSystem()
    {
        this.unloadSoundSystem();
        this.loadSoundSystem();
        MinecraftForge.EVENT_BUS.post(new SoundLoadEvent(this));
    }

    /**
     * Tries to add the paulscode library and the relevant codecs. If it fails, the master volume  will be set to zero.
     */
    private synchronized void loadSoundSystem()
    {
        if (!this.loaded)
        {
            try
            {
                (new Thread(new Runnable()
                {
                    private static final String __OBFID = "CL_00001142";
                    public void run()
                    {
                        SoundSystemConfig.setLogger(new SoundSystemLogger()
                        {
                            private static final String __OBFID = "CL_00002378";
                            public void message(String p_message_1_, int p_message_2_)
                            {
                                if (!p_message_1_.isEmpty())
                                {
                                    SoundManager.logger.info(p_message_1_);
                                }
                            }
                            public void importantMessage(String p_importantMessage_1_, int p_importantMessage_2_)
                            {
                                if (!p_importantMessage_1_.isEmpty())
                                {
                                    SoundManager.logger.warn(p_importantMessage_1_);
                                }
                            }
                            public void errorMessage(String p_errorMessage_1_, String p_errorMessage_2_, int p_errorMessage_3_)
                            {
                                if (!p_errorMessage_2_.isEmpty())
                                {
                                    SoundManager.logger.error("Error in class \'" + p_errorMessage_1_ + "\'");
                                    SoundManager.logger.error(p_errorMessage_2_);
                                }
                            }
                        });
                        SoundManager.this.sndSystem = SoundManager.this.new SoundSystemStarterThread(null);
                        SoundManager.this.loaded = true;
                        SoundManager.this.sndSystem.setMasterVolume(SoundManager.this.options.getSoundLevel(SoundCategory.MASTER));
                        SoundManager.logger.info(SoundManager.LOG_MARKER, "Sound engine started");
                    }
                }, "Sound Library Loader")).start();
            }
            catch (RuntimeException runtimeexception)
            {
                logger.error(LOG_MARKER, "Error starting SoundSystem. Turning off sounds & music", runtimeexception);
                this.options.setSoundLevel(SoundCategory.MASTER, 0.0F);
                this.options.saveOptions();
            }
        }
    }

    /**
     * Returns the sound level (between 0.0 and 1.0) for a category, but 1.0 for the master sound category
     */
    private float getSoundCategoryVolume(SoundCategory p_148595_1_)
    {
        return p_148595_1_ != null && p_148595_1_ != SoundCategory.MASTER ? this.options.getSoundLevel(p_148595_1_) : 1.0F;
    }

    /**
     * Adjusts volume for currently playing sounds in this category
     */
    public void setSoundCategoryVolume(SoundCategory p_148601_1_, float p_148601_2_)
    {
        if (this.loaded)
        {
            if (p_148601_1_ == SoundCategory.MASTER)
            {
                this.sndSystem.setMasterVolume(p_148601_2_);
            }
            else
            {
                Iterator iterator = this.categorySounds.get(p_148601_1_).iterator();

                while (iterator.hasNext())
                {
                    String s = (String)iterator.next();
                    ISound isound = (ISound)this.playingSounds.get(s);
                    float f1 = this.getNormalizedVolume(isound, (SoundPoolEntry)this.playingSoundPoolEntries.get(isound), p_148601_1_);

                    if (f1 <= 0.0F)
                    {
                        this.stopSound(isound);
                    }
                    else
                    {
                        this.sndSystem.setVolume(s, f1);
                    }
                }
            }
        }
    }

    /**
     * Cleans up the Sound System
     */
    public void unloadSoundSystem()
    {
        if (this.loaded)
        {
            this.stopAllSounds();
            this.sndSystem.cleanup();
            this.loaded = false;
        }
    }

    /**
     * Stops all currently playing sounds
     */
    public void stopAllSounds()
    {
        if (this.loaded)
        {
            Iterator iterator = this.playingSounds.keySet().iterator();

            while (iterator.hasNext())
            {
                String s = (String)iterator.next();
                this.sndSystem.stop(s);
            }

            this.playingSounds.clear();
            this.delayedSounds.clear();
            this.tickableSounds.clear();
            this.categorySounds.clear();
            this.playingSoundPoolEntries.clear();
            this.playingSoundsStopTime.clear();
        }
    }

    public void updateAllSounds()
    {
        ++this.playTime;
        Iterator iterator = this.tickableSounds.iterator();
        String s;

        while (iterator.hasNext())
        {
            ITickableSound itickablesound = (ITickableSound)iterator.next();
            itickablesound.update();

            if (itickablesound.isDonePlaying())
            {
                this.stopSound(itickablesound);
            }
            else
            {
                s = (String)this.invPlayingSounds.get(itickablesound);
                this.sndSystem.setVolume(s, this.getNormalizedVolume(itickablesound, (SoundPoolEntry)this.playingSoundPoolEntries.get(itickablesound), this.sndHandler.getSound(itickablesound.getSoundLocation()).getSoundCategory()));
                this.sndSystem.setPitch(s, this.getNormalizedPitch(itickablesound, (SoundPoolEntry)this.playingSoundPoolEntries.get(itickablesound)));
                this.sndSystem.setPosition(s, itickablesound.getXPosF(), itickablesound.getYPosF(), itickablesound.getZPosF());
            }
        }

        iterator = this.playingSounds.entrySet().iterator();
        ISound isound;

        while (iterator.hasNext())
        {
            Entry entry = (Entry)iterator.next();
            s = (String)entry.getKey();
            isound = (ISound)entry.getValue();

            if (!this.sndSystem.playing(s))
            {
                int i = ((Integer)this.playingSoundsStopTime.get(s)).intValue();

                if (i <= this.playTime)
                {
                    int j = isound.getRepeatDelay();

                    if (isound.canRepeat() && j > 0)
                    {
                        this.delayedSounds.put(isound, Integer.valueOf(this.playTime + j));
                    }

                    iterator.remove();
                    logger.debug(LOG_MARKER, "Removed channel {} because it\'s not playing anymore", new Object[] {s});
                    this.sndSystem.removeSource(s);
                    this.playingSoundsStopTime.remove(s);
                    this.playingSoundPoolEntries.remove(isound);

                    try
                    {
                        this.categorySounds.remove(this.sndHandler.getSound(isound.getSoundLocation()).getSoundCategory(), s);
                    }
                    catch (RuntimeException runtimeexception)
                    {
                        ;
                    }

                    if (isound instanceof ITickableSound)
                    {
                        this.tickableSounds.remove(isound);
                    }
                }
            }
        }

        Iterator iterator1 = this.delayedSounds.entrySet().iterator();

        while (iterator1.hasNext())
        {
            Entry entry1 = (Entry)iterator1.next();

            if (this.playTime >= ((Integer)entry1.getValue()).intValue())
            {
                isound = (ISound)entry1.getKey();

                if (isound instanceof ITickableSound)
                {
                    ((ITickableSound)isound).update();
                }

                this.playSound(isound);
                iterator1.remove();
            }
        }
    }

    /**
     * Returns true if the sound is playing or still within time
     */
    public boolean isSoundPlaying(ISound p_148597_1_)
    {
        if (!this.loaded)
        {
            return false;
        }
        else
        {
            String s = (String)this.invPlayingSounds.get(p_148597_1_);
            return s == null ? false : this.sndSystem.playing(s) || this.playingSoundsStopTime.containsKey(s) && ((Integer)this.playingSoundsStopTime.get(s)).intValue() <= this.playTime;
        }
    }

    public void stopSound(ISound p_148602_1_)
    {
        if (this.loaded)
        {
            String s = (String)this.invPlayingSounds.get(p_148602_1_);

            if (s != null)
            {
                this.sndSystem.stop(s);
            }
        }
    }

    public void playSound(ISound sound)
    {
        if (this.loaded)
        {
            if (this.sndSystem.getMasterVolume() <= 0.0F)
            {
                logger.debug(LOG_MARKER, "Skipped playing soundEvent: {}, master volume was zero", new Object[] {sound.getSoundLocation()});
            }
            else
            {
                sound = ForgeHooksClient.playSound(this, sound);
                if (sound == null) return;

                SoundEventAccessorComposite soundeventaccessorcomposite = this.sndHandler.getSound(sound.getSoundLocation());

                if (soundeventaccessorcomposite == null)
                {
                    logger.warn(LOG_MARKER, "Unable to play unknown soundEvent: {}", new Object[] {sound.getSoundLocation()});
                }
                else
                {
                    SoundPoolEntry soundpoolentry = soundeventaccessorcomposite.cloneEntry();

                    if (soundpoolentry == SoundHandler.missing_sound)
                    {
                        logger.warn(LOG_MARKER, "Unable to play empty soundEvent: {}", new Object[] {soundeventaccessorcomposite.getSoundEventLocation()});
                    }
                    else
                    {
                        float f = sound.getVolume();
                        float f1 = 16.0F;

                        if (f > 1.0F)
                        {
                            f1 *= f;
                        }

                        SoundCategory soundcategory = soundeventaccessorcomposite.getSoundCategory();
                        float f2 = this.getNormalizedVolume(sound, soundpoolentry, soundcategory);
                        double d0 = (double)this.getNormalizedPitch(sound, soundpoolentry);
                        ResourceLocation resourcelocation = soundpoolentry.getSoundPoolEntryLocation();

                        if (f2 == 0.0F)
                        {
                            logger.debug(LOG_MARKER, "Skipped playing sound {}, volume was zero.", new Object[] {resourcelocation});
                        }
                        else
                        {
                            boolean flag = sound.canRepeat() && sound.getRepeatDelay() == 0;
                            String s = MathHelper.getRandomUuid(ThreadLocalRandom.current()).toString();

                            if (soundpoolentry.isStreamingSound())
                            {
                                this.sndSystem.newStreamingSource(false, s, getURLForSoundResource(resourcelocation), resourcelocation.toString(), flag, sound.getXPosF(), sound.getYPosF(), sound.getZPosF(), sound.getAttenuationType().getTypeInt(), f1);
                                MinecraftForge.EVENT_BUS.post(new PlayStreamingSourceEvent(this, sound, s));
                            }
                            else
                            {
                                this.sndSystem.newSource(false, s, getURLForSoundResource(resourcelocation), resourcelocation.toString(), flag, sound.getXPosF(), sound.getYPosF(), sound.getZPosF(), sound.getAttenuationType().getTypeInt(), f1);
                                MinecraftForge.EVENT_BUS.post(new PlaySoundSourceEvent(this, sound, s));
                            }

                            logger.debug(LOG_MARKER, "Playing sound {} for event {} as channel {}", new Object[] {soundpoolentry.getSoundPoolEntryLocation(), soundeventaccessorcomposite.getSoundEventLocation(), s});
                            this.sndSystem.setPitch(s, (float)d0);
                            this.sndSystem.setVolume(s, f2);
                            this.sndSystem.play(s);
                            this.playingSoundsStopTime.put(s, Integer.valueOf(this.playTime + 20));
                            this.playingSounds.put(s, sound);
                            this.playingSoundPoolEntries.put(sound, soundpoolentry);

                            if (soundcategory != SoundCategory.MASTER)
                            {
                                this.categorySounds.put(soundcategory, s);
                            }

                            if (sound instanceof ITickableSound)
                            {
                                this.tickableSounds.add((ITickableSound)sound);
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Normalizes pitch from parameters and clamps to [0.5, 2.0]
     */
    private float getNormalizedPitch(ISound p_148606_1_, SoundPoolEntry p_148606_2_)
    {
        return (float)MathHelper.clamp_double((double)p_148606_1_.getPitch() * p_148606_2_.getPitch(), 0.5D, 2.0D);
    }

    /**
     * Normalizes volume level from parameters.  Range [0.0, 1.0]
     */
    private float getNormalizedVolume(ISound p_148594_1_, SoundPoolEntry p_148594_2_, SoundCategory p_148594_3_)
    {
        return (float)MathHelper.clamp_double((double)p_148594_1_.getVolume() * p_148594_2_.getVolume(), 0.0D, 1.0D) * this.getSoundCategoryVolume(p_148594_3_);
    }

    /**
     * Pauses all currently playing sounds
     */
    public void pauseAllSounds()
    {
        Iterator iterator = this.playingSounds.keySet().iterator();

        while (iterator.hasNext())
        {
            String s = (String)iterator.next();
            logger.debug(LOG_MARKER, "Pausing channel {}", new Object[] {s});
            this.sndSystem.pause(s);
        }
    }

    /**
     * Resumes playing all currently playing sounds (after pauseAllSounds)
     */
    public void resumeAllSounds()
    {
        Iterator iterator = this.playingSounds.keySet().iterator();

        while (iterator.hasNext())
        {
            String s = (String)iterator.next();
            logger.debug(LOG_MARKER, "Resuming channel {}", new Object[] {s});
            this.sndSystem.play(s);
        }
    }

    /**
     * Adds a sound to play in n tick
     */
    public void playDelayedSound(ISound p_148599_1_, int p_148599_2_)
    {
        this.delayedSounds.put(p_148599_1_, Integer.valueOf(this.playTime + p_148599_2_));
    }

    private static URL getURLForSoundResource(final ResourceLocation p_148612_0_)
    {
        String s = String.format("%s:%s:%s", new Object[] {"mcsounddomain", p_148612_0_.getResourceDomain(), p_148612_0_.getResourcePath()});
        URLStreamHandler urlstreamhandler = new URLStreamHandler()
        {
            private static final String __OBFID = "CL_00001143";
            protected URLConnection openConnection(final URL p_openConnection_1_)
            {
                return new URLConnection(p_openConnection_1_)
                {
                    private static final String __OBFID = "CL_00001144";
                    public void connect() {}
                    public InputStream getInputStream() throws IOException
                    {
                        return Minecraft.getMinecraft().getResourceManager().getResource(p_148612_0_).getInputStream();
                    }
                };
            }
        };

        try
        {
            return new URL((URL)null, s, urlstreamhandler);
        }
        catch (MalformedURLException malformedurlexception)
        {
            throw new Error("TODO: Sanely handle url exception! :D");
        }
    }

    /**
     * Sets the listener of sounds
     */
    public void setListener(EntityPlayer p_148615_1_, float p_148615_2_)
    {
        if (this.loaded && p_148615_1_ != null)
        {
            float f1 = p_148615_1_.prevRotationPitch + (p_148615_1_.rotationPitch - p_148615_1_.prevRotationPitch) * p_148615_2_;
            float f2 = p_148615_1_.prevRotationYaw + (p_148615_1_.rotationYaw - p_148615_1_.prevRotationYaw) * p_148615_2_;
            double d0 = p_148615_1_.prevPosX + (p_148615_1_.posX - p_148615_1_.prevPosX) * (double)p_148615_2_;
            double d1 = p_148615_1_.prevPosY + (p_148615_1_.posY - p_148615_1_.prevPosY) * (double)p_148615_2_ + (double)p_148615_1_.getEyeHeight();
            double d2 = p_148615_1_.prevPosZ + (p_148615_1_.posZ - p_148615_1_.prevPosZ) * (double)p_148615_2_;
            float f3 = MathHelper.cos((f2 + 90.0F) * 0.017453292F);
            float f4 = MathHelper.sin((f2 + 90.0F) * 0.017453292F);
            float f5 = MathHelper.cos(-f1 * 0.017453292F);
            float f6 = MathHelper.sin(-f1 * 0.017453292F);
            float f7 = MathHelper.cos((-f1 + 90.0F) * 0.017453292F);
            float f8 = MathHelper.sin((-f1 + 90.0F) * 0.017453292F);
            float f9 = f3 * f5;
            float f10 = f4 * f5;
            float f11 = f3 * f7;
            float f12 = f4 * f7;
            this.sndSystem.setListenerPosition((float)d0, (float)d1, (float)d2);
            this.sndSystem.setListenerOrientation(f9, f6, f10, f11, f8, f12);
        }
    }

    @SideOnly(Side.CLIENT)
    class SoundSystemStarterThread extends SoundSystem
    {
        private static final String __OBFID = "CL_00001145";

        private SoundSystemStarterThread() {}

        public boolean playing(String p_playing_1_)
        {
            Object object = SoundSystemConfig.THREAD_SYNC;

            synchronized (SoundSystemConfig.THREAD_SYNC)
            {
                if (this.soundLibrary == null)
                {
                    return false;
                }
                else
                {
                    Source source = (Source)this.soundLibrary.getSources().get(p_playing_1_);
                    return source == null ? false : source.playing() || source.paused() || source.preLoad;
                }
            }
        }

        SoundSystemStarterThread(Object p_i45118_2_)
        {
            this();
        }
    }
}