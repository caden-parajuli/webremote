//! This build script touches the filesystem outside of the OUT_DIR directory.
//! This should be fine since this is a binary crate.

use std::{fs, io::Error, path::Path};

use lightningcss::{
    bundler::{Bundler, FileProvider},
    printer::PrinterOptions,
    stylesheet,
};
use oxc::{
    allocator::Allocator,
    codegen::{Codegen, CodegenOptions},
    minifier::{Minifier, MinifierOptions},
    parser::Parser,
    semantic::SemanticBuilder,
    span::SourceType,
    transformer::{TransformOptions, Transformer},
};
use parcel_sourcemap::SourceMap;

fn main() {
    let out_dir = "./dist";
    fs::create_dir_all(out_dir).unwrap();

    let js_public = ["index.ts", "service-worker.js"];
    let css_public_roots = ["index.css", "slider.css"];

    // Rerun if these change
    println!("cargo::rerun-if-changed=build.rs");
    for file in js_public {
        println!("cargo::rerun-if-changed=public/{file}");
    }
    for file in css_public_roots {
        println!("cargo::rerun-if-changed=public/{file}");
    }

    let js_res = bundle_js(out_dir, &js_public);
    let css_res = bundle_css(out_dir, &css_public_roots);

    css_res.expect("CSS Error");
    js_res.expect("JS Error");
}

fn bundle_js(out_dir: &str, js_public: &[&str]) -> Result<(), Box<dyn std::error::Error>> {
    let allocator = Allocator::default();
    let options = MinifierOptions::default();
    let codegen_options = CodegenOptions::minify();
    let transformer_options =
        TransformOptions::from_target_list(&["firefox146", "safari18", "chrome144"])?;

    for src in js_public {
        let src_path = Path::new("public").join(src);

        let dest_name = if src.ends_with(".ts") {
            &(src[0..src.len() - 3].to_owned() + ".js")
        } else {
            *src
        };
        let dest_path = Path::new(&out_dir).join(dest_name);

        let source_text = fs::read_to_string(&src_path)?;
        let source_type = SourceType::from_path(&src_path).unwrap();
        let mut program = Parser::new(&allocator, &source_text, source_type)
            .parse()
            .program;

        let semantic_builder = SemanticBuilder::new().with_check_syntax_error(true);
        let ret = semantic_builder.build(&program);
        for err in ret.errors.iter() {
            println!("cargo::error={err}");
        }
        let scoping = ret.semantic.into_scoping();

        let transformer = Transformer::new(&allocator, &src_path, &transformer_options);
        for err in transformer
            .build_with_scoping(scoping, &mut program)
            .errors
            .iter()
        {
            println!("cargo::error={err}");
        }

        let minifier = Minifier::new(options.clone());
        minifier.minify(&allocator, &mut program);

        let codegen = Codegen::new().with_options(codegen_options.clone());

        let code = codegen.build(&program).code;
        fs::write(dest_path, code)?;
    }
    Ok(())
}
fn bundle_css(out_dir: &str, css_public: &[&str]) -> Result<(), Box<dyn std::error::Error>> {
    for src in css_public {
        let src_path = Path::new("public").join(src);
        let dest_path = Path::new(&out_dir).join(src);

        let parse_options = stylesheet::ParserOptions::default();
        let provider = FileProvider::new();
        let mut source_map = SourceMap::new("./");
        let mut bundler = Bundler::new(&provider, Some(&mut source_map), parse_options);

        let mut stylesheet = match bundler.bundle(&src_path) {
            Ok(sheet) => Ok(sheet),
            Err(e) => Err(Error::new(std::io::ErrorKind::InvalidData, e.to_string())),
        }?;

        let minify_options = stylesheet::MinifyOptions::default();
        stylesheet.minify(minify_options).unwrap();

        let printer_options = PrinterOptions {
            minify: true,
            source_map: None,
            project_root: Some("./"),
            targets: lightningcss::targets::Targets::default(),
            analyze_dependencies: None,
            pseudo_classes: None,
        };
        fs::write(dest_path, stylesheet.to_css(printer_options)?.code)?;
    }

    Ok(())
}
