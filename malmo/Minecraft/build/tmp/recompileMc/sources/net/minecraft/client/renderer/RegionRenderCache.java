package net.minecraft.client.renderer;

import java.util.Arrays;
import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.tileentity.TileEntity;
import net.minecraft.util.BlockPos;
import net.minecraft.util.Vec3i;
import net.minecraft.world.ChunkCache;
import net.minecraft.world.World;
import net.minecraft.world.chunk.Chunk;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;

@SideOnly(Side.CLIENT)
public class RegionRenderCache extends ChunkCache
{
    private static final IBlockState DEFAULT_STATE = Blocks.air.getDefaultState();
    private final BlockPos position;
    private int[] combinedLights;
    private IBlockState[] blockStates;
    private static final String __OBFID = "CL_00002565";

    public RegionRenderCache(World worldIn, BlockPos posFromIn, BlockPos posToIn, int subIn)
    {
        super(worldIn, posFromIn, posToIn, subIn);
        this.position = posFromIn.subtract(new Vec3i(subIn, subIn, subIn));
        boolean flag = true;
        this.combinedLights = new int[8000];
        Arrays.fill(this.combinedLights, -1);
        this.blockStates = new IBlockState[8000];
    }

    public TileEntity getTileEntity(BlockPos pos)
    {
        int i = (pos.getX() >> 4) - this.chunkX;
        int j = (pos.getZ() >> 4) - this.chunkZ;
        return this.chunkArray[i][j].getTileEntity(pos, Chunk.EnumCreateEntityType.QUEUED);
    }

    public int getCombinedLight(BlockPos pos, int p_175626_2_)
    {
        int j = this.getPositionIndex(pos);
        int k = this.combinedLights[j];

        if (k == -1)
        {
            k = super.getCombinedLight(pos, p_175626_2_);
            this.combinedLights[j] = k;
        }

        return k;
    }

    public IBlockState getBlockState(BlockPos pos)
    {
        int i = this.getPositionIndex(pos);
        IBlockState iblockstate = this.blockStates[i];

        if (iblockstate == null)
        {
            iblockstate = this.getBlockStateRaw(pos);
            this.blockStates[i] = iblockstate;
        }

        return iblockstate;
    }

    private IBlockState getBlockStateRaw(BlockPos pos)
    {
        if (pos.getY() >= 0 && pos.getY() < 256)
        {
            int i = (pos.getX() >> 4) - this.chunkX;
            int j = (pos.getZ() >> 4) - this.chunkZ;
            return this.chunkArray[i][j].getBlockState(pos);
        }
        else
        {
            return DEFAULT_STATE;
        }
    }

    private int getPositionIndex(BlockPos p_175630_1_)
    {
        int i = p_175630_1_.getX() - this.position.getX();
        int j = p_175630_1_.getY() - this.position.getY();
        int k = p_175630_1_.getZ() - this.position.getZ();
        return i * 400 + k * 20 + j;
    }
}