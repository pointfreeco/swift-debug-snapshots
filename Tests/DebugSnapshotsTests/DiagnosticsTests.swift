#if canImport(Testing) && (os(macOS) || os(Linux) || os(Windows))
  import CompilationTesting
  import Testing

  @Suite struct DiagnosticsTests {
    @Test func `non-convertible object property`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          var model: Model = Model()
        }
        """
      } diagnostics: {
        """
          var model: Model = Model()
          ˄
          ╰─ warning: Property is a reference type that is not 'DebugSnapshotConvertible'; apply the @DebugSnapshot macro to conform, or apply a fix-it (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `optional, non-convertible reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          var model: Model?
        }
        """
      } diagnostics: {
        """
          var model: Model?
          ˄
          ╰─ warning: Property is a reference type that is not 'DebugSnapshotConvertible'; apply the @DebugSnapshot macro to conform, or apply a fix-it (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `collection of non-convertible references`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          var models: [Model] = []
        }
        """
      } diagnostics: {
        """
          var models: [Model] = []
          ˄
          ╰─ warning: Property is a reference type that is not 'DebugSnapshotConvertible'; apply the @DebugSnapshot macro to conform, or apply a fix-it (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `unannotated convertible reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        final class Feature {
          var child: Child = Child()
        }
        """
      } diagnostics: {
        """
          var child: Child = Child()
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `unannotated convertible optional reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        final class Feature {
          var child: Child?
        }
        """
      } diagnostics: {
        """
          var child: Child?
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `unannotated convertible collection of references`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        final class Feature {
          var children: [Child] = []
        }
        """
      } diagnostics: {
        """
          var children: [Child] = []
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `annotated convertible reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        final class Feature {
          @DebugSnapshotConvertible var child: Child = Child()
        }
        """
      }
    }

    @Test func `annotated ignored reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          @DebugSnapshotIgnored var model: Model = Model()
        }
        """
      }
    }

    @Test func `annotated tracked reference`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          @DebugSnapshotTracked var model: Model = Model()
        }
        """
      }
    }

    @Test func `missing type annotation`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        final class Feature {
          var model = Model()
        }
        """
      } diagnostics: {
        """
          var model = Model()
              ˄
              ╰─ error: Missing required type annotation (from macro 'DebugSnapshot')
              ╰─ note: Insert ': <#Type#>'
        """
      }
    }

    @Test func `struct infers convertible property`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        struct Child {
          var value = 0
        }

        @DebugSnapshot
        struct Feature {
          var child = Child()
        }
        """
      }
    }

    @Test func `struct non-convertible reference property`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        struct Feature {
          var model = Model()
        }
        """
      } diagnostics: {
        """
          var model = Model()
          ˄
          ╰─ warning: Property is a reference type that is not 'DebugSnapshotConvertible'; apply the @DebugSnapshot macro to conform, or apply a fix-it (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `enum non-convertible reference associated value`() {
      assertCompilation {
        """
        import DebugSnapshots

        class Model {}

        @DebugSnapshot
        enum Destination {
          case detail(Model)
        }
        """
      } diagnostics: {
        """
          case detail(Model)
          ˄
          ╰─ warning: Associated value is a reference type that is not 'DebugSnapshotConvertible'; apply the @DebugSnapshot macro to conform, or apply a fix-it (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `unannotated convertible associated value`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        enum Destination {
          case detail(Child)
        }
        """
      } diagnostics: {
        """
          case detail(Child)
          ˄
          ╰─ warning: Associated value must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        """
      }
    }

    @Test func `annotated convertible associated value`() {
      assertCompilation {
        """
        import DebugSnapshots

        @DebugSnapshot
        final class Child {
          var value = 0
        }

        @DebugSnapshot
        enum Destination {
          case count(Int)
          @DebugSnapshotConvertible case detail(Child)
        }
        """
      }
    }
  }
#endif
