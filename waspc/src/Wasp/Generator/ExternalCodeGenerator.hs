module Wasp.Generator.ExternalCodeGenerator
  ( genExternalCodeDir,
  )
where

import Data.List (isPrefixOf)
import StrongPath (File', Path', Rel, (</>))
import qualified StrongPath as SP
import qualified System.FilePath as FP
import qualified Wasp.AppSpec.ExternalCode as EC
import qualified Wasp.Generator.ExternalCodeGenerator.Common as C
import Wasp.Generator.ExternalCodeGenerator.Js (generateJsFile)
import qualified Wasp.Generator.FileDraft as FD
import Wasp.Generator.Monad (Generator)
import Wasp.Generator.WebAppGenerator.Common (asWebAppFile, webAppRootDirInProjectRootDir)

-- | Takes external code files from Wasp and generates them in new location as part of the generated project.
-- It might not just copy them but also do some changes on them, as needed.
genExternalCodeDir ::
  C.ExternalCodeGeneratorStrategy ->
  [EC.File] ->
  Generator [FD.FileDraft]
genExternalCodeDir strategy = mapM (genFile strategy)

genFile :: C.ExternalCodeGeneratorStrategy -> EC.File -> Generator FD.FileDraft
genFile strategy file
  | extension `elem` [".js", ".jsx"] = generateJsFile strategy file
  | isPublicDirFile =
      let relDstPath = webAppRootDirInProjectRootDir </> asWebAppFile (EC.filePathInExtCodeDir file)
          absSrcPath = EC.fileAbsPath file
       in return $ FD.createCopyFileDraft relDstPath absSrcPath
  | otherwise =
      let relDstPath = C._extCodeDirInProjectRootDir strategy </> dstPathInGenExtCodeDir
          absSrcPath = EC.fileAbsPath file
       in return $ FD.createCopyFileDraft relDstPath absSrcPath
  where
    dstPathInGenExtCodeDir :: Path' (Rel C.GeneratedExternalCodeDir) File'
    dstPathInGenExtCodeDir = C.castRelPathFromSrcToGenExtCodeDir $ EC.filePathInExtCodeDir file

    extension = FP.takeExtension $ SP.toFilePath $ EC.filePathInExtCodeDir file
    -- TODO: Make sure to only do this for client.
    isPublicDirFile = "public/" `isPrefixOf` SP.toFilePath (EC.filePathInExtCodeDir file)
